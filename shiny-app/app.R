library(shiny)
library(recipes)
library(httr)
library(magrittr)
library(shinymaterial)
library(purrr)
library(r2d3)

ui <- material_page(
  title = "Tensorflow with R",
  material_side_nav(
    fixed = TRUE,

    material_radio_button("contract", "Contract", choices = list("Month-to-month", "One year", "Two year")),

    material_radio_button("internet", "Internet Service", choices = list("DSL", "Fiber optic", "No")),

    material_dropdown("paperless", "Paperless Billing", choices = list("Yes", "No")),

    material_dropdown("payment", "Payment Method", choices = list("Electronic check", "Mailed check", "Bank transfer (automatic)", "Credit card (automatic)")),

    material_slider("monthly", "Monthly Charges", initial_value = 65, min_value = 12, max_value = 120),

    material_slider("total", "Total Charges", initial_value = 2200, min_value = 12, max_value = 8800),


    material_dropdown("phone", "Phone Service", choices = list("Yes", "No")),
    material_dropdown("multiple", "Multiple Lines", choices = list("Yes", "No", "No phone service")),

    material_dropdown("gender", "Gender", choices = list("Male", "Female")),
    material_dropdown("senior", "Senior Citizen", choices = list("No" = 0, "Yes" = 1)),
    material_dropdown("partner", "Partner", choices = list("Yes", "No")),
    material_dropdown("dependents", "Dependents", choices = list("Yes", "No")),

    material_dropdown("security", "Online Security", choices = list("Yes", "No", "No internet service"), selected = "No internet service"),
    material_dropdown("backup", "Online Backup", choices = list("Yes", "No", "No internet service"), selected = "No internet service"),
    material_dropdown("device", "Device Protection", choices = list("Yes", "No", "No internet service"), selected = "No internet service"),
    material_dropdown("support", "Tech support", choices = list("Yes", "No", "No internet service"), selected = "No internet service"),
    material_dropdown("tv", "Streaming TV", choices = list("Yes", "No", "No internet service"), selected = "No internet service"),
    material_dropdown("movies", "Streaming Movies", choices = list("Yes", "No", "No internet service"), selected = "No internet service")

  ),
  mainPanel(
    material_card(
      title = "Probability of Churn over time",
      d3Output("churn"), 
      depth = 5
    )
    
  )
)


server <- function(input, output, session) {
  load("rec_obj.RData")

  observeEvent(input$phone, {
    if (input$phone == "No") {
      dv <- "No phone service"
    } else {
      dv <- "No"
    }
    update_material_dropdown(session, "multiple", value = dv)
  })

  observeEvent(input$internet, {
    if (input$internet == "No") {
      dv <- "No internet service"
    } else {
      dv <- "No"
    }
    update_material_dropdown(session, "security", value = dv)
    update_material_dropdown(session, "device", value = dv)
    update_material_dropdown(session, "backup", value = dv)
    update_material_dropdown(session, "support", value = dv)
    update_material_dropdown(session, "tv", value = dv)
    update_material_dropdown(session, "movies", value = dv)
  })

  output$churn <- renderD3({
    tenure_bins <- c(1, 5, 1:8 * 10)

    selections <- data.frame(
      gender = input$gender,
      SeniorCitizen = as.integer(input$senior),
      Partner = input$partner,
      Dependents = input$dependents,
      # tenure = as.integer(input$tenure),
      tenure = tenure_bins,
      PhoneService = input$phone,
      MultipleLines = input$multiple,
      InternetService = input$internet,
      OnlineSecurity = input$security,
      OnlineBackup = input$backup,
      DeviceProtection = input$device,
      TechSupport = input$support,
      StreamingTV = input$tv,
      StreamingMovies = input$movies,
      Contract = input$contract,
      PaperlessBilling = input$paperless,
      PaymentMethod = input$payment,
      MonthlyCharges = input$monthly,
      TotalCharges = input$total
    )

    baked_selections <- bake(rec_obj, selections)
    baked_selections$Churn <- NULL

    body <- list(
      instances = list(
        map(1:10, ~as.numeric(baked_selections[.x, ]))
      )
    )
    r <- POST("http://colorado.rstudio.com:3939/content/1532/serving_default/predict", body = body, encode = "json")

    results <- jsonlite::fromJSON(content(r))$predictions[, , 1]
    results <- round(results, digits = 2)

    
    yr <- c(" yr", rep(" yrs", 9))
    
    churn <- data.frame(
      y = results,
      x = tenure_bins,
      label = paste0(tenure_bins, yr),
      value_label = paste0(results * 100, "%")
    )

    r2d3(churn, "col_plot.js")
  })
}


shinyApp(ui = ui, server = server)
