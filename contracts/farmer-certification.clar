;; Farmer Certification Verification Contract
;; Validates organic, pesticide-free, and other farming certifications

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-FARMER-NOT-FOUND (err u101))
(define-constant ERR-CERTIFICATION-EXPIRED (err u102))
(define-constant ERR-INVALID-CERTIFICATION (err u103))
(define-constant ERR-AUTHORITY-NOT-FOUND (err u104))

;; Data Variables
(define-data-var contract-owner principal tx-sender)

;; Data Maps
(define-map certification-authorities
  { authority-id: uint }
  {
    name: (string-ascii 100),
    principal: principal,
    active: bool,
    created-at: uint
  }
)

(define-map farmer-profiles
  { farmer: principal }
  {
    farm-name: (string-ascii 100),
    location: (string-ascii 200),
    contact-info: (string-ascii 100),
    registered-at: uint,
    active: bool
  }
)

(define-map farmer-certifications
  { farmer: principal, cert-type: (string-ascii 50) }
  {
    authority-id: uint,
    issued-date: uint,
    expiration-date: uint,
    certificate-hash: (buff 32),
    verified: bool
  }
)

;; Data Variables for IDs
(define-data-var next-authority-id uint u1)

;; Public Functions

;; Register a new certification authority
(define-public (register-authority (name (string-ascii 100)) (authority-principal principal))
  (let ((authority-id (var-get next-authority-id)))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (map-set certification-authorities
      { authority-id: authority-id }
      {
        name: name,
        principal: authority-principal,
        active: true,
        created-at: block-height
      }
    )
    (var-set next-authority-id (+ authority-id u1))
    (ok authority-id)
  )
)

;; Register a farmer profile
(define-public (register-farmer (farm-name (string-ascii 100)) (location (string-ascii 200)) (contact-info (string-ascii 100)))
  (begin
    (map-set farmer-profiles
      { farmer: tx-sender }
      {
        farm-name: farm-name,
        location: location,
        contact-info: contact-info,
        registered-at: block-height,
        active: true
      }
    )
    (ok true)
  )
)

;; Add certification for a farmer
(define-public (add-certification
  (farmer principal)
  (cert-type (string-ascii 50))
  (authority-id uint)
  (expiration-date uint)
  (certificate-hash (buff 32)))
  (let ((authority (map-get? certification-authorities { authority-id: authority-id })))
    (asserts! (is-some authority) ERR-AUTHORITY-NOT-FOUND)
    (asserts! (get active (unwrap-panic authority)) ERR-AUTHORITY-NOT-FOUND)
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-eq tx-sender (get principal (unwrap-panic authority)))) ERR-NOT-AUTHORIZED)
    (asserts! (> expiration-date block-height) ERR-INVALID-CERTIFICATION)

    (map-set farmer-certifications
      { farmer: farmer, cert-type: cert-type }
      {
        authority-id: authority-id,
        issued-date: block-height,
        expiration-date: expiration-date,
        certificate-hash: certificate-hash,
        verified: true
      }
    )
    (ok true)
  )
)

;; Verify farmer certification
(define-public (verify-certification (farmer principal) (cert-type (string-ascii 50)))
  (let ((certification (map-get? farmer-certifications { farmer: farmer, cert-type: cert-type })))
    (match certification
      cert-data (begin
        (asserts! (get verified cert-data) ERR-INVALID-CERTIFICATION)
        (asserts! (> (get expiration-date cert-data) block-height) ERR-CERTIFICATION-EXPIRED)
        (ok true)
      )
      ERR-INVALID-CERTIFICATION
    )
  )
)

;; Read-only Functions

;; Get farmer profile
(define-read-only (get-farmer-profile (farmer principal))
  (map-get? farmer-profiles { farmer: farmer })
)

;; Get farmer certification
(define-read-only (get-farmer-certification (farmer principal) (cert-type (string-ascii 50)))
  (map-get? farmer-certifications { farmer: farmer, cert-type: cert-type })
)

;; Get certification authority
(define-read-only (get-certification-authority (authority-id uint))
  (map-get? certification-authorities { authority-id: authority-id })
)

;; Check if farmer is certified
(define-read-only (is-farmer-certified (farmer principal) (cert-type (string-ascii 50)))
  (match (map-get? farmer-certifications { farmer: farmer, cert-type: cert-type })
    cert-data (and (get verified cert-data) (> (get expiration-date cert-data) block-height))
    false
  )
)

;; Get contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)
