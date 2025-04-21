;; Supplier Verification Contract
;; Validates component manufacturers in a decentralized manufacturing system

(define-data-var contract-owner principal tx-sender)

;; Data structure for supplier information
(define-map suppliers
  { supplier-id: uint }
  {
    name: (string-utf8 100),
    address: (string-utf8 200),
    contact: (string-utf8 100),
    verified: bool,
    verification-date: uint,
    verifier: principal
  }
)

;; Track all supplier IDs for enumeration
(define-data-var next-supplier-id uint u1)

;; Authorization check
(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner))
)

;; Register a new supplier (can be done by anyone)
(define-public (register-supplier (name (string-utf8 100)) (address (string-utf8 200)) (contact (string-utf8 100)))
  (let
    (
      (supplier-id (var-get next-supplier-id))
    )
    ;; Insert the supplier data
    (map-insert suppliers
      { supplier-id: supplier-id }
      {
        name: name,
        address: address,
        contact: contact,
        verified: false,
        verification-date: u0,
        verifier: tx-sender
      })

    ;; Increment the supplier ID counter
    (var-set next-supplier-id (+ supplier-id u1))

    (ok supplier-id)
  )
)

;; Verify a supplier (only by contract owner)
(define-public (verify-supplier (supplier-id uint))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? suppliers { supplier-id: supplier-id })) (err u404)) ;; Supplier not found

    (map-set suppliers
      { supplier-id: supplier-id }
      (merge (unwrap-panic (map-get? suppliers { supplier-id: supplier-id }))
        {
          verified: true,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    )

    (ok true)
  )
)

;; Revoke verification (only by contract owner)
(define-public (revoke-verification (supplier-id uint))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (asserts! (is-some (map-get? suppliers { supplier-id: supplier-id })) (err u404)) ;; Supplier not found

    (map-set suppliers
      { supplier-id: supplier-id }
      (merge (unwrap-panic (map-get? suppliers { supplier-id: supplier-id }))
        {
          verified: false,
          verification-date: block-height,
          verifier: tx-sender
        }
      )
    )

    (ok true)
  )
)

;; Get supplier information
(define-read-only (get-supplier (supplier-id uint))
  (map-get? suppliers { supplier-id: supplier-id })
)

;; Check if a supplier is verified
(define-read-only (is-supplier-verified (supplier-id uint))
  (default-to false (get verified (map-get? suppliers { supplier-id: supplier-id })))
)

;; Transfer contract ownership
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-contract-owner) (err u403)) ;; Unauthorized
    (var-set contract-owner new-owner)
    (ok true)
  )
)
