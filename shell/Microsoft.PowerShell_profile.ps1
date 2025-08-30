# --- PSReadLine Configuration ---

# Set the prediction view to be inline (like zsh-autosuggestions)
Set-PSReadLineOption -PredictionViewStyle InlineView

# Use both command history and installed plugins for suggestions
Set-PSReadLineOption -PredictionSource HistoryAndPlugin


# --- Starship Prompt ---
# Initializes Starship. This should be the last line in the profile.
Invoke-Expression (&starship init powershell)
