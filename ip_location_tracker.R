library(RMySQL)
library(tidyverse)
library(lubridate)
library(rio)
library(httr)
library(shiny)
library(shinyjs)
library(DT)
library(sys)

ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$style(
      HTML(
        "
        .button_color {
          background-color: #8BC34A; /* Light green */
          border-color: white;
          color: white;
        }
        .table-container {
          max-width: 100%; /* Adjusted for full width */
          margin-top: 20px; /* Margin top adjusted */
        }
        .sidebar {
          padding-right: 20px; /* Increase right padding for sidebar */
        }
        .main-content {
          padding-left: 100px; /* Increase left padding for main content */
        }
        "
      )
    )
  ),
  
  titlePanel("Dashboard IP"),
  sidebarLayout(
    sidebarPanel(
      class = "sidebar",  # Apply sidebar CSS class
      textInput('email', 'Enter email'), 
      dateRangeInput('date_range', 'Select Date Range', start = NULL, end = NULL),
      actionButton("process", "PROCESS"),
      downloadButton("download", "Download Processed CSV", style = "color: grey;"),
      # downloadButton("download", 
      #                tags$span("Download Processed CSV", style = "color: black;"),
      #                style = "background-color: grey; border-color: white; color: white;"
      # ),
      br(),
      br(),
      textOutput("ready")  # Text output below the main panel
    ),
    mainPanel(
      class = "main-content",  # Apply main panel CSS class
      tags$div(class = "table-container",
               tableOutput("tableOutput")
      )
    )
  )
)



server <- function(input, output, session) {
  result_f <- reactiveVal(NULL)
  
  observeEvent(input$process, {
    req(input$email)
    
    result <- tryCatch({
      # Database Connection
      db <- dbConnect(
        MySQL(),
        dbname = "x",
        user = "y",
        password = "z",
        host = "w",
        port = 3306
      )
      
      # Fetch users with the provided email
      users <- tbl(db, "users") %>%
        select(id, email, full_name) %>% 
        #filter(email=='rrxd74@gmail.com') %>% 
        filter(email == input$email) %>%
        collect() 
      
      if (length(users) == 0) {
        stop("No users found with the given email.")
      }
      start_date <- input$date_range[1]
      end_date <- input$date_range[2]
      
      ip_log <- tbl(db, "user_activity_log_trackings") %>% 
        filter(user_id %in% !!users$id) %>% 
        collect()%>% 
        filter(as_date(created_at)>=as_date(start_date) & as_date(created_at)<=as_date(end_date) )
      
      # Filter IPs for the given account_id
      ips_to_check <- ip_log %>% distinct(ip)
      
      get_ip_location <- function(ip) {
        api_key <- "your_key"
        url <- paste0("http://ipwhois.pro/", ip, "?key=", api_key)
        response <- GET(url)
        content <- content(response, "parsed")
        
        if (is.null(content$country)) {
          content$country <- NA
        }
        if (is.null(content$region)) {
          content$region <- NA
        }
        if (is.null(content$city)) {
          content$city <- NA
        }
        
        return(content)
      }
      
      ip_locations <- ips_to_check %>%
        rowwise() %>%
        mutate(location = list(get_ip_location(ip))) %>%
        ungroup() %>%
        mutate(
          country = sapply(location, function(x) x$country),
          region = sapply(location, function(x) x$regionName),
          city = sapply(location, function(x) x$city)
        ) %>%
        select(ip, country, region, city)
      
      dbDisconnect(db)
      
      final <- ip_log %>% 
        select(user_id, dashboard_ip = ip, login_time = created_at) %>% 
        left_join(select(users, user_id = id, name = full_name)) %>% 
        left_join(select(ip_locations, dashboard_ip = ip, country, region, city)) %>% 
        select(name, dashboard_ip, country, city, login_time)
      
      final
      
    }, error = function(e) {
      return(paste(
        "Some error happened!",
        "Error message:",
        e$message,
        sep = "\n"
      ))
    }, finally = {
      lapply(dbListConnections(MySQL()), dbDisconnect)
    })
    
    result_f(result)
  })
  
  observe({
    shinyjs::disable('download')
  })
  
  observeEvent(input$email, {
    output$ready <- renderText({
      ""
    })
    shinyjs::removeClass("download", "button_color")
    shinyjs::disable("download")
  })
  
  observe({
    res <- result_f()
    if (is.data.frame(res)) {
      shinyjs::addClass("download", "button_color")
      shinyjs::enable("download")
      output$ready <- renderText({
        "The file is ready for download."
      })
      output$tableOutput <- renderTable({
        res
      })
    } else if (is.character(res)) {
      shinyjs::removeClass("download", "button_color")
      shinyjs::disable("download")
      output$ready <- renderText({
        "There is an issue."
      })
      output$tableOutput <- renderTable({
        NULL  # Render an empty table or handle the error case as needed
      })
    }
  })
  
  output$download <- downloadHandler(
    filename = function() {
      paste(input$email ,".csv", sep = "")
    },
    content = function(file) {
      write.csv(result_f(), file, row.names = FALSE)
    }
  )
}

shinyApp(ui = ui, server = server)

