# R/a/dio Firefox Extension: Fetching and Displaying Track Information

This document explains how the R/a/dio Firefox extension retrieves and displays the current song's title and artist information.

## API Endpoint

The extension uses the following API endpoint to fetch current track information:

https://r-a-d.io/api


## Fetching Data

The `popup.js` file contains the following code to fetch data from the API:

```
javascript
fetch('https://r-a-d.io/api')
.then(response => response.json())
.then(data => {
const trackInfo = document.getElementById('trackInfo');
const artistInfo = document.getElementById('artistInfo');
const [artist, title] = data.main.np.split(' - ');
trackInfo.textContent = title;
artistInfo.textContent = artist;
})
.catch(error => {
console.error('Error fetching the API:', error);
});
```

## API Response Structure

The API returns a JSON object. The relevant part of the response looks like this:

```
json
{
"main": {
"np": "Artist - Title",
// ... other fields ...
}
}
```


## Parsing and Displaying Information

1. The code extracts the `np` (now playing) field from the `main` object in the API response.
2. It splits the `np` string into artist and title using the " - " separator.
3. The title is displayed in the `trackInfo` HTML element.
4. The artist is displayed in the `artistInfo` HTML element.

This process ensures that users always see up-to-date information about the currently playing track when they open the extension popup.