# General Information
# If using on different laptops there are a few variables that will need to be updated
# $csvFilePath : This should be where ever hoster saves song books by default
# $accessToken  : this is the token used to access this repo and upload the newest song_book html file

Write-output """
!!!!Generating a rockin list of Songs!!!!
This process can take up to 10+ minutes
Just let this run in the background 🙂
"""

# Specify the path to the CSV file
$csvFilePath = "C:\ProgramData\mtu.com\Hoster\SongBook.csv"

# Specify the path to the HTML output file
$desktopPath = [System.IO.Path]::Combine([System.Environment]::GetFolderPath('Desktop'))
$htmlOutputPath = $desktopPath + "\Rockin_Robs_Karaoke.html"

# Read CSV data
$data = Import-Csv -Path $csvFilePath -Delimiter ',' -Header "Title", "Artist", "Duet", "Genre", "Code" | Sort-Object -Property "Title", "Artist" | Group-Object -Property "Title", "Artist" | ForEach-Object { $_.Group[0] }

# Create HTML template
$htmlTemplate = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rockin Robs Karaoke Song List</title>
    <script>
        function search() {
            var input, filter, table, tr, td, i, txtValue;
            input = document.getElementById("searchInput");
            filter = input.value.toUpperCase();
            table = document.getElementById("songsTable");
            tr = table.getElementsByTagName("tr");
            for (i = 0; i < tr.length; i++) {
                var found = false;
                td = tr[i].getElementsByTagName("td");
                for (var j = 0; j < td.length; j++) {
                    txtValue = td[j].textContent || td[j].innerText;
                    if (txtValue.toUpperCase().indexOf(filter) > -1) {
                        found = true;
                        break;
                    }
                }
                if (found) {
                    tr[i].style.display = "";
                } else {
                    tr[i].style.display = "none";
                }
            }
        }
    </script>
</head>
<body>

    <h1>Rockin Robs Karaoke Song List</h1>

    <input type="text" id="searchInput" onkeyup="search()" placeholder="Search for any field">

    <table border="1" id="songsTable">
        <tr>
            <th>Title</th>
            <th>Artist</th>
            <th>Duet</th>
        </tr>
"@

# Add CSV data to the HTML template

$totalRows = $data.Count
$progress = 0

foreach ($row in $data) {
    $progress++
    $percentage = [math]::Round(($progress / $totalRows) * 100)
    Write-Progress -PercentComplete $percentage -Status "Processing Rows" -Activity "Creating HTML"
    $htmlTemplate += @"
        <tr>
            <td>$($row.Title)</td>
            <td>$($row.Artist)</td>
            <td>$($row.Duet)</td>
        </tr>
"@
}

# Close HTML template
$htmlTemplate += @"
    </table>

</body>
</html>
"@

# Write HTML content to the output file
$htmlTemplate | Out-File -FilePath $htmlOutputPath -Encoding UTF8

Write-Progress "Rockin Rob's Song list created at: $htmlOutputPath"

# GitHub repository information
$repositoryOwner = "jodycherpes"
$repositoryName = "Rockin_Robs"

# Personal access token with the "repo" scope
$accessToken = ""

# File path and name to upload
$filePath = $htmlOutputPath
$fileName = "Karaoke_songs.html"

# Content for the file
$fileContent = Get-Content -Raw $filePath

# GitHub API URL for getting the current content of the file
$getContentUrl = "https://api.github.com/repos/$repositoryOwner/$repositoryName/contents/$fileName"

# Make a request to get the current content of the file
$currentContent = Invoke-RestMethod -Uri $getContentUrl -Headers @{
    Authorization = "Bearer $accessToken"
    Accept = "application/vnd.github.v3+json"
}

# Extract the SHA from the response
$currentSha = $currentContent.sha

# Create a base64-encoded string of the file content
$fileContentBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fileContent))

# Create a JSON body for the API request
$body = @{
    message = "Update $fileName via API"
    content = $fileContentBase64
    sha = $currentSha  # Include the SHA in the request
} | ConvertTo-Json

# GitHub API URL for uploading a file to the repository
$uploadUrl = "https://api.github.com/repos/$repositoryOwner/$repositoryName/contents/$fileName"

# Make the API request to upload the file
$response = Invoke-RestMethod -Uri $uploadUrl -Headers @{
    Authorization = "Bearer $accessToken"
    Accept = "application/vnd.github.v3+json"
} -Method PUT -Body $body
