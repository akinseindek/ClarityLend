💡 ClarityLend
==============

* * * * *

📄 Overview
-----------

The `AI-LendingRiskCalculator` smart contract, now named **ClarityLend** for brevity and clarity, is a sophisticated, decentralized application built on the **Clarity** blockchain language. It implements an **AI-driven lending risk assessment** system that evaluates borrower creditworthiness using a **multi-factor weighted scoring algorithm**. This system uses dynamic factors like **annual income**, **total debt**, **employment stability**, and **payment history** to generate a comprehensive predictive risk score.

Its primary functions are:

1.  **Register and manage borrower profiles** (e.g., credit data, financial health).

2.  **Calculate a composite, AI-derived risk score** for loan applicants.

3.  **Automatically determine an appropriate interest rate** based on the calculated risk.

4.  Manage the **lifecycle of loan applications** (pending, approved, disbursed).

* * * * *

🛠️ Contract Details
--------------------

### Constants

| Constant Name | Value | Description |
| --- | --- | --- |
| `contract-owner` | `tx-sender` | The address with privileged functions (e.g., loan approval/disbursement). |
| `err-owner-only` | `u100` | Error for functions restricted to the contract owner. |
| `min-credit-score` | `u300` | Minimum allowed credit score. |
| `max-credit-score` | `u850` | Maximum allowed credit score. |
| `low-risk-threshold` | `u700` | Score threshold for the 'low' risk category. |
| `base-rate` | `u500` (5%) | Base interest rate in basis points (bp). |
| `low-risk-rate` | `u300` (3%) | Interest rate for low-risk borrowers. |

> **Note:** Interest rates are expressed in **basis points (bp)**, where 100 bp=1%.

### Data Maps and Variables

#### Maps

1.  **`borrower-profiles` (Principal → { ... }):** Stores comprehensive financial and behavioral data for registered users.

2.  **`loan-applications` (Uint → { ... }):** Stores details for loan requests in the application pipeline.

3.  **`active-loans` (Uint → { ... }):** Stores active, disbursed loans and their repayment status.

#### Variables

| Variable Name | Type | Initial Value | Description |
| --- | --- | --- | --- |
| `loan-id-nonce` | `uint` | `u0` | Counter for generating unique loan/application IDs. |
| `total-loans-issued` | `uint` | `u0` | Total number of loans disbursed by the contract. |
| `total-amount-disbursed` | `uint` | `u0` | Cumulative sum of all principal amounts disbursed. |
| `ai-model-version` | `uint` | `u1` | The current version of the risk assessment model. |

* * * * *

🔒 Private Functions (Internal Logic)
-------------------------------------

These functions contain the core financial and risk assessment logic and cannot be called directly by external accounts; they are only used internally by the public functions.

| Function Name | Description | Used By |
| --- | --- | --- |
| `calculate-dti-ratio` | Calculates the Debt-to-Income ratio (DTI), returning the percentage ×100. | `calculate-comprehensive-risk-score` |
| `calculate-payment-score` | Calculates a score (0-100) based on on-time payments versus total loans/payments. | `calculate-comprehensive-risk-score` |
| `get-risk-category` | Determines the borrower's risk category ("low", "medium", "high", "very-high") based on a composite score. | `register-borrower-profile`, `calculate-comprehensive-risk-score` |
| `calculate-interest-rate` | Assigns an interest rate (in basis points) corresponding to the calculated risk score. | `apply-for-loan`, `calculate-comprehensive-risk-score` |
| `calculate-monthly-payment` | Calculates a simplified estimate of the required monthly payment using a straight-line amortization model (Principal + Total Interest) / Term. | `disburse-loan` |

* * * * *

💻 Public Functions (API)
-------------------------

### **1\. `register-borrower-profile`**

Registers or updates a borrower's full financial and behavioral data, including their initial risk category based on their input `credit-score`.

### **2\. `apply-for-loan`**

Submits a new loan application. It validates parameters, uses the stored profile's `credit-score` to determine an immediate `risk-score` and `interest-rate`, and sets the status to "pending."

### **3\. `approve-loan` (Owner Only)**

The contract owner changes a pending loan application's status to "approved."

### **4\. `disburse-loan` (Owner Only)**

The contract owner moves an approved application to the `active-loans` map, calculates the `monthly-payment`, and updates overall contract statistics (`total-loans-issued`, `total-amount-disbursed`).

### **5\. `record-payment`**

Allows the borrower to record a payment against their active loan, reducing the `outstanding-balance` and incrementing `payments-made`.

### **6\. `calculate-comprehensive-risk-score`**

The **Advanced AI-Powered Risk Assessment Function**. This function executes the full, detailed multi-factor weighted scoring algorithm, combining credit score, DTI, payment history, and other factors to generate a comprehensive `final-risk-score` and recommendation.

* * * * *

🔎 Read-Only Functions
----------------------

These functions allow anyone to query the state of the contract.

-   `get-borrower-profile (borrower principal)`

-   `get-loan-application (loan-id uint)`

-   `get-active-loan (loan-id uint)`

-   `get-contract-stats`

* * * * *

🔬 AI-Powered Risk Assessment Methodology
-----------------------------------------

The final risk score is a highly granular metric resulting from a weighted average of several component scores, ensuring a fair and predictive outcome.

### Weighted Risk Components

The composite score (normalized 0-100) is calculated based on:

| Component | Weight | Impact |
| --- | --- | --- |
| **Credit Score** (Normalized) | **35%** | Traditional credit health. |
| **DTI Score** (Inverse) | **25%** | Debt burden relative to income. |
| **Payment History Score** | **20%** | Behavioral pattern for debt repayment. |
| **Employment Stability Score** | **10%** | Stability of income source. |
| **Default History Score** | **10%** | Direct indicator of credit risk. |

The composite score is then adjusted for **Loan-to-Income (LTI) ratio** and mapped back to the 500-850 range to produce the **`final-risk-score`**.

* * * * *

🤝 Contribution
---------------

This contract is open for community peer review and enhancement. Developers are encouraged to propose improvements, especially to the **`calculate-comprehensive-risk-score`** logic.

### Style Guide

All contributions must adhere to the standard Clarity style guide.

* * * * *

📜 License
----------

### The MIT License (MIT)

Copyright (c) 2025 ClarityLend Contributors

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
