# Specify the filter pattern
$filterPattern = "updateAcquireFence"

# Function to continuously filter logs
function FilterLogs {
    # Execute adb logcat and filter using Select-String
    adb logcat | Select-String -NotMatch $filterPattern
}

# Continuous filtering loop
while ($true) {
    # Call the function to filter logs
    FilterLogs
}
