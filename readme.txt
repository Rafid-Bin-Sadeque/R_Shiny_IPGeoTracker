# Shiny IP Locator

## Overview
This Shiny application processes user login data to find IP addresses and their corresponding locations using the IPWHOIS service. Users can input an email and date range to retrieve and download the processed data as a CSV file.

## Features
- Email Input Users can enter an email address to search for user activity.
- Date Range Selection Users can specify a date range for filtering login activities.
- Data Processing The app connects to a MySQL database to retrieve user and IP information, then uses IPWHOIS to get location details.
- Error Handling If an error occurs during processing, a message is displayed.
- Download Processed Data Users can download the processed data as a CSV file.
- Table Display Displays the processed data in a table format within the app.

## Libraries Used
- `RMySQL`
- `tidyverse`
- `lubridate`
- `rio`
- `httr`
- `shiny`
- `shinyjs`
- `DT`
- `sys`

## User Interface
- Title Panel Dashboard IP
- Sidebar Panel Contains inputs for email, date range, process button, and download button.
- Main Panel Displays the processed data in a table format.
- Custom Styling Uses custom CSS for styling buttons and layout.

## Server Logic
1. Reactive Value `result_f` to store the processing result.
2. Process Button Event
   - Reads the email input and date range.
   - Connects to the MySQL database and retrieves user and IP information.
   - Filters login activities based on the date range.
   - Uses IPWHOIS to get location details for the IPs.
   - Handles errors and closes the database connection.
3. Download Button Enabled when processing is successful, allows downloading the processed data.
4. UI Updates Updates the UI based on the processing status and displays the data in a table.

## How to Use
1. Enter Email Input the email address you want to search for.
2. Select Date Range Choose the date range for filtering login activities.
3. Process the Data Click the PROCESS button to start processing the data.
4. Download the Result Once processing is complete, click the Download Processed CSV button to download the result.
5. View the Table The processed data will be displayed in a table within the app.

---