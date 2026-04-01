#!/usr/bin/env python3
"""PetClaw MCP Server — 品質ツール群をMCPプロトコルで公開
teams-ai-agent のDynamic MCP Tool Discoveryパターンを応用。
外部AIエージェントがPetClawの品質チェックを呼び出せるようにする。

Usage:
    python3 petclaw_mcp_server.py [--port 8765]
    
MCP Tools exposed:
    - petclaw.agent_lint: エージェント定義の品質検証
    - petclaw.deslop: GDScriptスロップ検出
    - petclaw.drift: 設計文書ドリフト検出
    - petclaw.stats: プロジェクト統計
"""

import json
import subprocess
import sys
import os
from pathlib import Path

# Simple JSON-RPC style MCP server (stdio transport)
# Compatible with MCP protocol for tool discovery and execution

TOOLS = [
    {
        "name": "petclaw.agent_lint",
        "description": "Validate PetClaw Agent Teams configuration files (agents, commands, CLAUDE.md)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.deslop",
        "description": "Detect AI-generated GDScript quality degradation patterns (3-phase analysis)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.drift",
        "description": "Check drift between design documents and GDScript implementation",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
    {
        "name": "petclaw.stats",
        "description": "Get PetClaw project statistics (files, lines, systems, forms)",
        "inputSchema": {
            "type": "object",
            "properties": {
                "project_root": {"type": "string", "description": "Project root path", "default": "."}
            }
        }
    },
]


def find_project_root():
    """Auto-discover project root by looking for CLAUDE.md"""
    current = Path(__file__).resolve().parent
    for _ in range(5):
        if (current / "CLAUDE.md").exists():
            return str(current)
        current = current.parent
    return "."


def run_tool(name, args):
    """Execute a PetClaw quality tool and return results"""
    project_root = args.get("project_root", find_project_root())
    tool_dir = Path(__file__).resolve().parent
    
    tool_map = {
        "petclaw.agent_lint": "petclaw_agent_lint.py",
        "petclaw.deslop": "petclaw_deslop.py",
        "petclaw.drift": "petclaw_drift.py",
    }
    
    if name == "petclaw.stats":
        return get_project_stats(project_root)
    
    if name not in tool_map:
        return {"error": f"Unknown tool: {name}"}
    
    script = tool_dir / tool_map[name]
    if not script.exists():
        return {"error": f"Tool script not found: {script}"}
    
    try:
        result = subprocess.run(
            [sys.executable, str(script), "--project-root", project_root, "--json"],
            capture_output=True, text=True, timeout=60
        )
        try:
            return json.loads(result.stdout)
        except json.JSONDecodeError:
            return {"stdout": result.stdout, "stderr": result.stderr, "exit_code": result.returncode}
    except subprocess.TimeoutExpired:
        return {"error": "Tool execution timed out (60s)"}
    except Exception as e:
        return {"error": str(e)}


def get_project_stats(project_root):
    """Gather project statistics"""
    root = Path(project_root)
    scripts_dir = root / "godot_project" / "scripts"
    kb_dir = root / "knowledge_base"
    
    gd_files = list(scripts_dir.rglob("*.gd")) if scripts_dir.exists() else []
    total_lines = 0
    for f in gd_files:
        try:
            total_lines += len(f.read_text(encoding="utf-8").splitlines())
        except:
            pass
    
    kb_files = list(kb_dir.glob("*.md")) if kb_dir.exists() else []
    
    agents_dir = root / ".claude" / "agents"
    commands_dir = root / ".claude" / "commands"
    agents = [f.stem for f in agents_dir.glob("*.md")] if agents_dir.exists() else []
    commands = [f.stem for f in commands_dir.glob("*.md")] if commands_dir.exists() else []
    
    return {
        "gdscript_files": len(gd_files),
        "gdscript_lines": total_lines,
        "knowledge_base_docs": len(kb_files),
        "agents": agents,
        "commands": commands,
        "agent_count": len(agents),
        "command_count": len(commands),
    }


def handle_request(request):
    """Handle a JSON-RPC MCP request"""
    method = request.get("method", "")
    req_id = request.get("id")
    params = request.get("params", {})
    
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "petclaw-quality", "version": "1.0.0"}
            }
        }
    
    elif method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {"tools": TOOLS}
        }
    
    elif method == "tools/call":
        tool_name = params.get("name", "")
        tool_args = params.get("arguments", {})
        result = run_tool(tool_name, tool_args)
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "result": {
                "content": [{"type": "text", "text": json.dumps(result, ensure_ascii=False, indent=2)}]
            }
        }
    
    elif method == "notifications/initialized":
        return None  # No response for notifications
    
    else:
        return {
            "jsonrpc": "2.0",
            "id": req_id,
            "error": {"code": -32601, "message": f"Method not found: {method}"}
        }


def main():
    """Run MCP server on stdio transport"""
    import sys
    
    sys.stderr.write("PetClaw MCP Server started (stdio transport)\n")
    
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        
        try:
            request = json.loads(line)
            response = handle_request(request)
            if response is not None:
                sys.stdout.write(json.dumps(response) + "\n")
                sys.stdout.flush()
        except json.JSONDecodeError:
            error_response = {
                "jsonrpc": "2.0",
                "id": None,
                "error": {"code": -32700, "message": "Parse error"}
            }
            sys.stdout.write(json.dumps(error_response) + "\n")
            sys.stdout.flush()


if __name__ == "__main__":
    main()
