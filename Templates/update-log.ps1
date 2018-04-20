function Update-Log ($text) {
    $LogTextBox.AppendText("$text")
    $LogTextBox.Update()
    $LogTextBox.ScrollToCaret()
}