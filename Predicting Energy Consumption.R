# Load the dataset
tetuan_city_power = read.csv("Tetuan City power consumption.csv") 


# Select variables of temperature and three power consumption zones
new_data = tetuan_city_power[c(2, 7:9)] 
head(new_data)

# Select unique a dataset with unique values
tetaun_data = unique(new_data)
View(tetaun_data)

# Select training and test datasets
set.seed(1000)

train_sample_index = sample(seq_len(nrow(tetaun_data)), 3000)
train_data = tetaun_data[train_sample_index, ]
test_data = tetaun_data[-train_sample_index, ]

# Integrate three power consumption values and stored in as a new variable
train_data$Power_Consumption = train_data$Zone.1.Power.Consumption + 
                                train_data$Zone.2..Power.Consumption +
                                train_data$Zone.3..Power.Consumption

View(train_data)

# Select temperature variable and integrated power consumption variable
power_data = train_data[c(1,5)]
View(power_data)
dim(power_data)  

# Calculate the mean of integrated power consumption values
mean_power_consumption = mean(power_data$Power_Consumption)
mean_power_consumption

# Print 1 if power consumption > mean value and 0 if power consumption < mean value 
# Stored 1 and 0 as Y variable
power_data$Y = ifelse(power_data$Power_Consumption > mean_power_consumption, 1, 0)
View(power_data)

table(power_data$Y)

new_data = power_data[c(1,3)]
View(new_data)

################## Random Walk Metropolis Algorithm #######################

set.seed(1000)

# Define the formula
formula = Y ~ Temperature

# Initial values for the coefficients
Initial_coefficient = c(0, 0)

# Number of iterations for the Random Walk Metropolis Algorithm
Num_iterations = 10000

# Proposal Distribution Standard Deviation
proposal_sd = c(0.01, 0.01)

# Store the sample coeffients
sample_coff = matrix(0, Num_iterations, length(Initial_coefficient))

# Initialize the coefficient
sample_coff[1, ] = Initial_coefficient


for (i in 2:Num_iterations) {
# Propose new coefficients using normal distribution
  proposed_coff = rnorm(length(Initial_coefficient), mean = sample_coff[i-1, ], sd = proposal_sd)
  
  # Calculate log likelihood for proposed cofficients
  linear_predict_proposed = proposed_coff[1] + (proposed_coff[2] * new_data$Temperature)
  log_likelihood_proposed = sum(new_data$Y * linear_predict_proposed - log(1 + exp(linear_predict_proposed)))
  
  linear_predict_current = sample_coff[i-1, 1] + (sample_coff[i-1, 2] * new_data$Temperature)
  log_likelihood_current = sum(new_data$Y * linear_predict_current - log(1 + exp(linear_predict_current)))
  
  # Calculate log prior for current and proposed coeffients
  log_prior_proposed = sum(dnorm(proposed_coff, mean = 0, sd = 1, log = TRUE))
  log_prior_current = sum(dnorm(sample_coff[i-1, ], mean = 0, sd = 1, log = TRUE))
  
  # Calculate the Acceptance Probability
  accept_prob = min(1, exp(log_likelihood_proposed + log_prior_proposed - log_likelihood_current - log_prior_current))
  
  # Accept or Reject proposed coeffients
  if (runif(1) < accept_prob) {
    sample_coff[i, ] = proposed_coff
  } else {
    sample_coff[i, ] = sample_coff[i-1, ]
  }

}

# Acceptance Rate
accepted <- sum(apply(sample_coff[-1, ] != sample_coff[-Num_iterations, ], 1, any))
accept_rate <- accepted / Num_iterations
accept_rate

#Display the summary of sample coefficients
summary(sample_coff)  

burn_in = 3000
sample = sample_coff[-(1:burn_in), ]

# Create trace plots for coefficients

par(mfrow = c(3,2))
plot(sample[ ,1], type = "l", xlab = "Iteration", ylab = "beta 0", main = "Trace Plot - Beta 0")
abline(h = mean(sample[ ,1]), col = "red")

plot(sample[ ,2], type = "l", xlab = "Iteration", ylab = "beta 1", main = "Trace Plot - Beta 1")
abline(h = mean(sample[ ,2]), col = "red")

# Density plots for the coefficients
plot(density(sample[ ,1]), type = "l", xlab = "beta 0", ylab = "Density", main = "Posterior Distribution - Beta 0")
abline(v = mean(sample[ ,1]), col = "red")

plot(density(sample[ ,2]), type = "l", xlab = "beta 1", ylab = "Density", main = "Posterior Distribution - Beta 1")
abline(v = mean(sample[ ,2]), col = "red")

# Plot Histograms for coefficients

hist(sample[ ,1], main = "Histogram of Beta 0 Posterior")
abline(v = mean(sample[ ,1]), col = "red")

hist(sample[ ,2], main = "Histogram of Beta 1 Posterior")
abline(v = mean(sample[ ,2]), col = "red")

## Formulate the probability 

# Calculate the mean of beta0 and beta1 coefficients

beta_0 = mean(sample[, 1])
beta_1 = mean(sample[, 2])

# Calculate Pr(Y=1|Temperature) for each temperature value
temperature = new_data$Temperature
pr_Y_1 = 1/(1 + exp(-(beta_0 + beta_1 * temperature)))

ord = order(temperature)

# Plot Pr(Y=1|Temperature) against Temperature
par(mfrow=(c(1,1)))
plot(temperature, new_data$Y, pch = 20, col = "gray",
     xlab = "Temperature", ylab = "Probability / Observed Y", main = "Logistic Regression Fit")
lines(temperature[ord],  pr_Y_1[ord],  type = "l", 
      lwd = 3,
      col = "blue" )


############## Predict Probability ############################

# Predict values using test data

test_data$Power_Consumption = test_data$Zone.1.Power.Consumption + 
                              test_data$Zone.2..Power.Consumption +
                              test_data$Zone.3..Power.Consumption

View(test_data)
test_power = test_data[c(1,5)]

test_power$Y = ifelse(test_power$Power_Consumption > mean_power_consumption, 1, 0)
View(test_power)

test_model_data = test_power[c(1,3)]
View(test_model_data)


test_temperature = test_model_data$Temperature
test_prob = 1/(1 + exp(-(beta_0 + beta_1 * test_temperature)))
test_pred = ifelse(test_prob > 0.5, 1, 0)

# Confusion Matrix
conf_matrix = table(predicted = test_pred, Actual = test_model_data$Y)
print(conf_matrix)

# Calculate Accuracy
accuracy = mean(test_pred == test_model_data$Y)
print(paste("Test Accuracy:", round(accuracy, 3)))

# Calculate Precision
precision = conf_matrix[2,2] / sum(conf_matrix[2, ])
precision

# Calculate Recall
recall = conf_matrix[2,2] / sum(conf_matrix[ ,2])
recall

# Calculate F1
f1 = 2 * (precision * recall) / (precision + recall)
f1


############# Future Predictions ##############

# Suggest temperature values
temperature_values = c(10, 15, 20, 25, 30, 35, 40, 45, 50, 55)

# Calculate Prediction Probability
prediction_prob = 1/(1 + exp(-(beta_0 + beta_1 * temperature_values)))

# Create Y variable
predicted_Y = ifelse(prediction_prob > 0.5, 1, 0)

# Future Predictions
future_predictions = data.frame(Temperature = temperature_values,
                                Probability = prediction_prob,
                                Predicted_Y = predicted_Y)
print(future_predictions)

# Plot predicted values

plot(temperature_values, prediction_prob,
     type = "b", col = "purple",
     pch = 19, xlab = "Temperature", ylab = "Predicted Probability", main = "Future Prediction of Power Consumption")

