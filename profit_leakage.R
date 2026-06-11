library(tidyverse)

superstore <- read.csv("data/superstore_cleaned.csv")

yearly <- superstore %>%
  group_by(year) %>%
  summarize(revenue = sum(sales), margin = sum(profit)/sum(sales), .groups = "drop")

coef <- max(yearly$revenue)/max(yearly$margin)

ggplot(yearly, aes(factor(year))) +
  geom_col(aes(y = revenue), fill = "#90A4AE") +
  geom_line(aes(y = margin * coef, group = 1), color = "#C62828", linewidth = 1.2) +
  geom_point(aes(y = margin * coef), color = "#C62828", size = 3) +
  scale_y_continuous(labels = scales::dollar,
                     sec.axis = sec_axis(~ . / coef, labels = scales::percent, name = "Profit Margin")) +
  labs(title = "Revenue climbed 51% while Margin plateaued",
       x = NULL, y = "Revenue") + theme_minimal(base_size = 13)

ggsave("output/00_revenue_vs_margin.png", width = 9, height = 5.5, dpi = 300)

leak <- superstore %>%
  group_by(discount) %>%
  summarize(
    orders = n(),
    avg_profit = mean(profit),
    .groups = "drop"
  ) %>%
  mutate(profitable = avg_profit > 0)

leak <- leak %>%
  mutate(disc_lbl = scales::percent(discount, accuracy = 1))

loss_above_line <- superstore %>%
  filter(discount >= .30) %>%
  summarize(total = sum(profit)) %>% pull(total)

ggplot(leak, aes(disc_lbl, avg_profit, fill = profitable)) +
  geom_col() +
  geom_hline(yintercept = 0, linewidth = 0.4) +
  scale_fill_manual(values = c('TRUE' = "#2E7D32", 'FALSE' = "#C62828")) +
  labs(title = "Profit per Order Dropoff at 30% Discount",
       subtitle = "Avg Profit/Order by Discount",
       x ="Discount", y = "Avg Profit per Order", fill = "Profitable") +
  theme_minimal(base_size = 13)

ggsave("output/01_breakpoint.png", width = 9, height = 5.5, units = "in", dpi = 300)

conc <- superstore %>%
  filter(discount >= 0.30) %>%
  group_by(sub_category) %>%
  summarize(loss = sum(profit), orders = n(), .groups = "drop") %>%
  arrange(loss) %>%
  mutate(cum_share = cumsum(loss)/sum(loss))

conc_top <- conc %>%
  slice_head(n=8) %>%
  arrange(loss)

ggplot(conc_top, aes(loss, reorder(sub_category, loss))) +
  geom_col(fill = "#C62828") +
  geom_text(aes(label = scales::dollar(loss, accuracy = 1)),
            hjust = 1.1, color = "white", size = 3.5) +
  scale_x_continuous(labels = scales::dollar) +
  labs(title = "Three Sub-Categories Drive +70% of Discount Losses",
       subtitle = "Profit on Orders Discounted >30%",
       x = "Profit (Loss)", y = NULL) + 
  theme_minimal(base_size = 13)

ggsave("output/02_loss_concentration.png", width = 9, height = 5.5, dpi = 300)

current <- sum(superstore$profit)
ceiling <- current - loss_above_line
scenario <- tibble(
  case = c("Today", "Cap @20%, 50% Held", "Cap @20%, All Held"),
  profit = c(current, current - 0.5*loss_above_line, ceiling)
)

scenario <- scenario %>%
  mutate(case = factor(case, levels = case))

ggplot(scenario, aes(case, profit, fill = case)) +
  geom_col(show.legend = FALSE) +
  geom_text(aes(label = scales::dollar(profit, accuracy =1)), vjust = -0.5, size = 3.8) +
  scale_fill_manual(values = c("#9E9E9E", "#66BB6A", "#2E7D32")) +
  scale_y_continuous(labels = scales::dollar, expand = expansion(mult = c(0, .12))) +
  labs(title = "A 20% Discount Cap could lift Profit to ~47%",
       subtitle = "Scenario assumes capped orders sell at break-even (upper bound)",
       x = NULL, y = "Total Profit") +
  theme_minimal(base_size = 13)

ggsave("output/03_recovery_scenarios.png", width = 9, height = 5.5, dpi = 300)
