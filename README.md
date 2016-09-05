# TouristHelper
iOS app to load Google Places onto Google Map

Source code for an iOS app using xCode, Swift to display Google map with the below features

1. Map centers to the location of the user
2. Uses Googles places to fetch restaurants at a radius of 1000 meters and displays it on the map
3. Let the user pick a start location from the map.
4. From the selected location a straight line is drawn to connect the closest restaurant, and from there to the next closest restaurant and so on until all restaurants are covered. Finally it closes the loop by connecting the last restaurant to the starting point.
