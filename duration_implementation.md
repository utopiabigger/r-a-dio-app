# Duration Implementation in Radio Stream Player

The duration functionality in the Radio Stream Player project was implemented using a combination of API data and client-side calculations. Here's an overview of how it works:

## 1. Fetching Track Information

The project fetches track information from the r/a/dio API, which provides data about the currently playing track, including its start time and end time.

javascript
function fetchMainData() {
return fetch('https://r-a-d.io/api')
.then(response => response.json())
.then(data => {
// Process and store the API response
return data;
});
}

## 2. Extracting Duration Information

When updating the track info, the start time and end time are extracted from the API response:

@Codebase Can you create a markdown file explaining how you got the duration working on this project please. 

Certainly! I'll create a markdown file explaining how the duration functionality was implemented in this project. Here's the content for the file:
javascript
function fetchMainData() {
return fetch('https://r-a-d.io/api')
.then(response => response.json())
.then(data => {
// Process and store the API response
return data;
});
}
javascript
function updateTrackInfo(trackData) {
if (trackData && trackData.main) {
const main = trackData.main;
currentTrackStartTime = main.start_time 1000;
if (main.end_time && main.start_time) {
currentTrackDuration = main.end_time - main.start_time;
} else {
currentTrackDuration = null;
}
updateDurationDisplay();
}
}

## 3. Calculating and Displaying Duration

The `updateDurationDisplay` function is responsible for calculating the elapsed time and updating the UI:

@Codebase Can you create a markdown file explaining how you got the duration working on this project please. 

Certainly! I'll create a markdown file explaining how the duration functionality was implemented in this project. Here's the content for the file:
javascript
function fetchMainData() {
return fetch('https://r-a-d.io/api')
.then(response => response.json())
.then(data => {
// Process and store the API response
return data;
});
}
javascript
function updateTrackInfo(trackData) {
if (trackData && trackData.main) {
const main = trackData.main;
currentTrackStartTime = main.start_time 1000;
if (main.end_time && main.start_time) {
currentTrackDuration = main.end_time - main.start_time;
} else {
currentTrackDuration = null;
}
updateDurationDisplay();
}
}
javascript
function updateDurationDisplay() {
const currentTime = new Date();
const elapsedTime = Math.max(0, (currentTime - new Date(currentTrackStartTime)) / 1000);
const formatTime = (seconds) => {
if (seconds === null || isNaN(seconds)) return '--:--';
const mins = Math.floor(seconds / 60);
const secs = Math.floor(seconds % 60);
return ${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')};
};
if (currentTrackDuration === null) {
durationInfo.textContent = formatTime(elapsedTime);
} else {
durationInfo.textContent = ${formatTime(elapsedTime)} / ${formatTime(currentTrackDuration)};
}
// Update progress bar
if (currentTrackDuration !== null) {
const progress = (elapsedTime / currentTrackDuration) 100;
progressBar.style.width = ${Math.min(progress, 100)}%;
} else {
progressBar.style.width = '0%';
}
requestAnimationFrame(updateDurationDisplay);
}

## 4. Continuous Updates

The `updateDurationDisplay` function is called using `requestAnimationFrame`, ensuring smooth and efficient updates:

javascript
requestAnimationFrame(updateDurationDisplay);

## 5. Handling Unknown Durations

If the track duration is not available from the API, the code gracefully handles this by displaying only the elapsed time and hiding the progress bar.

## Conclusion

This implementation provides a robust way to display track duration and progress, adapting to both known and unknown track lengths. It combines real-time API data with client-side calculations to offer users accurate and up-to-date information about the currently playing track.

This markdown file provides a comprehensive explanation of how the duration functionality was implemented in the Radio Stream Player project. It covers the key aspects of fetching data, extracting relevant information, calculating and displaying the duration, and handling edge cases like unknown track lengths.