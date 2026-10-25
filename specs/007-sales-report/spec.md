# Feature Specification: Sales Report

## Goal

Give an Admin a compact operational report for completed COD orders.

## User Stories

1. As an Admin, I can choose a recent reporting period and see completed-order count, revenue, and average order value.
2. As an Admin, I can see top-selling items ranked by quantity and revenue.

## Acceptance Scenarios

- Given completed and incomplete orders exist, when a report loads, then only Completed orders in the selected date range are counted.
- Given Admin changes the period, when data reloads, then all metrics and top items use that same range.
- Given no completed orders exist, then a clear zero-data state is shown.
- Loading, error, retry, selected-period, and empty states are visible.

## Constraints

- Revenue is the sum of `totalAmount` snapshots from Completed COD orders.
- Item ranking uses immutable order-item snapshots.
- Supported presets are Last 7 days, Last 30 days, and This month.

