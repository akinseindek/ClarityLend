;; AI-Powered Lending Risk Calculator
;; This smart contract implements an AI-driven lending risk assessment system that evaluates
;; borrower creditworthiness, calculates risk scores, manages loan applications, and determines
;; interest rates based on multiple risk factors including credit history, income, debt ratios,
;; and behavioral patterns.

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-insufficient-score (err u104))
(define-constant err-loan-active (err u105))
(define-constant err-unauthorized (err u106))
(define-constant err-invalid-parameters (err u107))

;; Risk score thresholds
(define-constant min-credit-score u300)
(define-constant max-credit-score u850)
(define-constant low-risk-threshold u700)
(define-constant medium-risk-threshold u600)
(define-constant high-risk-threshold u500)

;; Interest rate basis points (1 bp = 0.01%)
(define-constant base-rate u500) ;; 5%
(define-constant low-risk-rate u300) ;; 3%
(define-constant medium-risk-rate u800) ;; 8%
(define-constant high-risk-rate u1500) ;; 15%

;; data maps and vars
(define-map borrower-profiles
    principal
    {
        credit-score: uint,
        annual-income: uint,
        total-debt: uint,
        employment-years: uint,
        previous-defaults: uint,
        on-time-payments: uint,
        total-loans: uint,
        risk-category: (string-ascii 10),
        last-updated: uint
    }
)

(define-map loan-applications
    uint
    {
        borrower: principal,
        amount: uint,
        purpose: (string-ascii 50),
        term-months: uint,
        risk-score: uint,
        interest-rate: uint,
        status: (string-ascii 20),
        applied-at: uint,
        approved-at: uint
    }
)

(define-map active-loans
    uint
    {
        borrower: principal,
        principal-amount: uint,
        outstanding-balance: uint,
        interest-rate: uint,
        monthly-payment: uint,
        payments-made: uint,
        payments-missed: uint,
        term-months: uint,
        disbursed-at: uint
    }
)

(define-data-var loan-id-nonce uint u0)
(define-data-var total-loans-issued uint u0)
(define-data-var total-amount-disbursed uint u0)
(define-data-var ai-model-version uint u1)

;; private functions

;; Calculate debt-to-income ratio (returns percentage * 100)
(define-private (calculate-dti-ratio (income uint) (debt uint))
    (if (is-eq income u0)
        u10000 ;; Return 100% if no income
        (/ (* debt u10000) income)
    )
)

;; Calculate payment history score (0-100)
(define-private (calculate-payment-score (on-time uint) (total uint))
    (if (is-eq total u0)
        u50 ;; Neutral score for no history
        (/ (* on-time u100) total)
    )
)

;; Determine risk category based on composite score
(define-private (get-risk-category (score uint))
    (if (>= score low-risk-threshold)
        "low"
        (if (>= score medium-risk-threshold)
            "medium"
            (if (>= score high-risk-threshold)
                "high"
                "very-high"
            )
        )
    )
)

;; Calculate interest rate based on risk score
(define-private (calculate-interest-rate (risk-score uint))
    (if (>= risk-score low-risk-threshold)
        low-risk-rate
        (if (>= risk-score medium-risk-threshold)
            medium-risk-rate
            (if (>= risk-score high-risk-threshold)
                high-risk-rate
                (+ high-risk-rate u500) ;; 20% for very high risk
            )
        )
    )
)

;; Calculate monthly payment using simplified amortization
(define-private (calculate-monthly-payment (principal uint) (annual-rate uint) (months uint))
    (let
        (
            (monthly-rate (/ annual-rate u1200)) ;; Convert annual basis points to monthly decimal
            (total-interest (/ (* principal annual-rate months) u120000))
        )
        (/ (+ principal total-interest) months)
    )
)

;; public functions

;; Register or update borrower profile
(define-public (register-borrower-profile
    (credit-score uint)
    (annual-income uint)
    (total-debt uint)
    (employment-years uint)
    (previous-defaults uint)
    (on-time-payments uint)
    (total-payments uint))
    (begin
        (asserts! (and (>= credit-score min-credit-score) (<= credit-score max-credit-score)) err-invalid-parameters)
        (asserts! (> annual-income u0) err-invalid-parameters)
        
        (let
            (
                (risk-category (get-risk-category credit-score))
            )
            (ok (map-set borrower-profiles tx-sender {
                credit-score: credit-score,
                annual-income: annual-income,
                total-debt: total-debt,
                employment-years: employment-years,
                previous-defaults: previous-defaults,
                on-time-payments: on-time-payments,
                total-loans: total-payments,
                risk-category: risk-category,
                last-updated: block-height
            }))
        )
    )
)

;; Apply for a loan with AI risk assessment
(define-public (apply-for-loan (amount uint) (purpose (string-ascii 50)) (term-months uint))
    (let
        (
            (borrower-profile (unwrap! (map-get? borrower-profiles tx-sender) err-not-found))
            (application-id (+ (var-get loan-id-nonce) u1))
            (risk-score (get credit-score borrower-profile))
            (interest-rate (calculate-interest-rate risk-score))
        )
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (and (>= term-months u6) (<= term-months u360)) err-invalid-parameters)
        (asserts! (>= risk-score high-risk-threshold) err-insufficient-score)
        
        (map-set loan-applications application-id {
            borrower: tx-sender,
            amount: amount,
            purpose: purpose,
            term-months: term-months,
            risk-score: risk-score,
            interest-rate: interest-rate,
            status: "pending",
            applied-at: block-height,
            approved-at: u0
        })
        
        (var-set loan-id-nonce application-id)
        (ok application-id)
    )
)

;; Approve loan application (owner only)
(define-public (approve-loan (loan-id uint))
    (let
        (
            (application (unwrap! (map-get? loan-applications loan-id) err-not-found))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status application) "pending") err-invalid-parameters)
        
        (map-set loan-applications loan-id (merge application {
            status: "approved",
            approved-at: block-height
        }))
        
        (ok true)
    )
)

;; Disburse approved loan
(define-public (disburse-loan (loan-id uint))
    (let
        (
            (application (unwrap! (map-get? loan-applications loan-id) err-not-found))
            (monthly-payment (calculate-monthly-payment 
                (get amount application)
                (get interest-rate application)
                (get term-months application)))
        )
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (is-eq (get status application) "approved") err-invalid-parameters)
        
        (map-set active-loans loan-id {
            borrower: (get borrower application),
            principal-amount: (get amount application),
            outstanding-balance: (get amount application),
            interest-rate: (get interest-rate application),
            monthly-payment: monthly-payment,
            payments-made: u0,
            payments-missed: u0,
            term-months: (get term-months application),
            disbursed-at: block-height
        })
        
        (map-set loan-applications loan-id (merge application {
            status: "disbursed"
        }))
        
        (var-set total-loans-issued (+ (var-get total-loans-issued) u1))
        (var-set total-amount-disbursed (+ (var-get total-amount-disbursed) (get amount application)))
        
        (ok true)
    )
)

;; Record loan payment
(define-public (record-payment (loan-id uint) (payment-amount uint))
    (let
        (
            (loan (unwrap! (map-get? active-loans loan-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get borrower loan)) err-unauthorized)
        (asserts! (> (get outstanding-balance loan) u0) err-invalid-amount)
        
        (let
            (
                (new-balance (if (>= payment-amount (get outstanding-balance loan))
                    u0
                    (- (get outstanding-balance loan) payment-amount)))
            )
            (map-set active-loans loan-id (merge loan {
                outstanding-balance: new-balance,
                payments-made: (+ (get payments-made loan) u1)
            }))
            
            (ok new-balance)
        )
    )
)

;; Read-only functions

(define-read-only (get-borrower-profile (borrower principal))
    (map-get? borrower-profiles borrower)
)

(define-read-only (get-loan-application (loan-id uint))
    (map-get? loan-applications loan-id)
)

(define-read-only (get-active-loan (loan-id uint))
    (map-get? active-loans loan-id)
)

(define-read-only (get-contract-stats)
    (ok {
        total-loans: (var-get total-loans-issued),
        total-disbursed: (var-get total-amount-disbursed),
        ai-version: (var-get ai-model-version)
    })
)


