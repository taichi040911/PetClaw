#!/bin/bash
# PetClaw Quality Tools Installation Script

echo "Installing dependencies for PetClaw Quality Tools..."

# Check for Python 3
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found. Please install Python 3.7+"
    exit 1
fi

# Install click and pyyaml
echo "Installing click and pyyaml..."
python3 -m pip install click pyyaml

echo ""
echo "Installation complete!"
echo ""
echo "Available tools:"
echo "  - petclaw_agent_lint.py (Agent Teams configuration validator)"
echo "  - petclaw_deslop.py (AI-generated code pattern detector)"
echo "  - petclaw_drift.py (Design/implementation drift detector)"
echo ""
echo "Try: python3 petclaw_agent_lint.py --help"
