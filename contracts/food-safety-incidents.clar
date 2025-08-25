;; Food Safety Incident Reporting Contract
;; Tracks and responds to reports of foodborne illness or contamination

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-INCIDENT-NOT-FOUND (err u501))
(define-constant ERR-INVALID-STATUS (err u502))
(define-constant ERR-INVALID-SEVERITY (err u503))
(define-constant ERR-PRODUCT-NOT-FOUND (err u504))

;; Data Variables
(define-data-var contract-owner principal tx-sender)
(define-data-var next-incident-id uint u1)
(define-data-var next-recall-id uint u1)

;; Data Maps
(define-map incident-reports
  { incident-id: uint }
  {
    reporter: principal,
    product-id: uint,
    incident-type: (string-ascii 50),
    severity: uint,
    description: (string-ascii 500),
    location: (string-ascii 200),
    date-occurred: uint,
    date-reported: uint,
    status: (string-ascii 20),
    assigned-investigator: (optional principal)
  }
)

(define-map incident-investigations
  { incident-id: uint }
  {
    investigator: principal,
    findings: (string-ascii 500),
    root-cause: (string-ascii 200),
    corrective-actions: (string-ascii 300),
    investigation-status: (string-ascii 20),
    completion-date: (optional uint)
  }
)

(define-map product-recalls
  { recall-id: uint }
  {
    incident-id: uint,
    product-id: uint,
    recall-type: (string-ascii 30),
    reason: (string-ascii 200),
    scope: (string-ascii 100),
    initiated-by: principal,
    initiated-date: uint,
    status: (string-ascii 20),
    affected-quantity: uint
  }
)

(define-map incident-notifications
  { incident-id: uint, recipient: principal }
  {
    notification-type: (string-ascii 30),
    message: (string-ascii 300),
    sent-date: uint,
    acknowledged: bool,
    acknowledgment-date: (optional uint)
  }
)

(define-map authorized-investigators
  { investigator: principal }
  {
    name: (string-ascii 100),
    credentials: (string-ascii 200),
    active: bool,
    authorized-by: principal,
    authorization-date: uint
  }
)

;; Public Functions

;; Report a food safety incident
(define-public (report-incident
  (product-id uint)
  (incident-type (string-ascii 50))
  (severity uint)
  (description (string-ascii 500))
  (location (string-ascii 200))
  (date-occurred uint))
  (let ((incident-id (var-get next-incident-id)))
    (asserts! (<= severity u5) ERR-INVALID-SEVERITY)
    (asserts! (<= date-occurred block-height) ERR-INVALID-STATUS)

    (map-set incident-reports
      { incident-id: incident-id }
      {
        reporter: tx-sender,
        product-id: product-id,
        incident-type: incident-type,
        severity: severity,
        description: description,
        location: location,
        date-occurred: date-occurred,
        date-reported: block-height,
        status: "REPORTED",
        assigned-investigator: none
      }
    )

    (var-set next-incident-id (+ incident-id u1))
    (ok incident-id)
  )
)

;; Authorize an investigator
(define-public (authorize-investigator
  (investigator principal)
  (name (string-ascii 100))
  (credentials (string-ascii 200)))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)

    (map-set authorized-investigators
      { investigator: investigator }
      {
        name: name,
        credentials: credentials,
        active: true,
        authorized-by: tx-sender,
        authorization-date: block-height
      }
    )
    (ok true)
  )
)

;; Assign investigator to incident
(define-public (assign-investigator (incident-id uint) (investigator principal))
  (let ((incident (map-get? incident-reports { incident-id: incident-id }))
        (investigator-auth (map-get? authorized-investigators { investigator: investigator })))
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (is-some incident) ERR-INCIDENT-NOT-FOUND)
    (asserts! (is-some investigator-auth) ERR-NOT-AUTHORIZED)
    (asserts! (get active (unwrap-panic investigator-auth)) ERR-NOT-AUTHORIZED)

    (map-set incident-reports
      { incident-id: incident-id }
      (merge (unwrap-panic incident)
        {
          assigned-investigator: (some investigator),
          status: "INVESTIGATING"
        }
      )
    )
    (ok true)
  )
)

;; Submit investigation findings
(define-public (submit-investigation
  (incident-id uint)
  (findings (string-ascii 500))
  (root-cause (string-ascii 200))
  (corrective-actions (string-ascii 300)))
  (let ((incident (map-get? incident-reports { incident-id: incident-id })))
    (asserts! (is-some incident) ERR-INCIDENT-NOT-FOUND)
    (asserts! (is-eq (some tx-sender) (get assigned-investigator (unwrap-panic incident))) ERR-NOT-AUTHORIZED)

    (map-set incident-investigations
      { incident-id: incident-id }
      {
        investigator: tx-sender,
        findings: findings,
        root-cause: root-cause,
        corrective-actions: corrective-actions,
        investigation-status: "COMPLETED",
        completion-date: (some block-height)
      }
    )

    ;; Update incident status
    (map-set incident-reports
      { incident-id: incident-id }
      (merge (unwrap-panic incident) { status: "INVESTIGATED" })
    )
    (ok true)
  )
)

;; Initiate product recall
(define-public (initiate-recall
  (incident-id uint)
  (product-id uint)
  (recall-type (string-ascii 30))
  (reason (string-ascii 200))
  (scope (string-ascii 100))
  (affected-quantity uint))
  (let ((recall-id (var-get next-recall-id))
        (incident (map-get? incident-reports { incident-id: incident-id })))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-some (map-get? authorized-investigators { investigator: tx-sender }))) ERR-NOT-AUTHORIZED)
    (asserts! (is-some incident) ERR-INCIDENT-NOT-FOUND)

    (map-set product-recalls
      { recall-id: recall-id }
      {
        incident-id: incident-id,
        product-id: product-id,
        recall-type: recall-type,
        reason: reason,
        scope: scope,
        initiated-by: tx-sender,
        initiated-date: block-height,
        status: "ACTIVE",
        affected-quantity: affected-quantity
      }
    )

    (var-set next-recall-id (+ recall-id u1))
    (ok recall-id)
  )
)

;; Send incident notification
(define-public (send-notification
  (incident-id uint)
  (recipient principal)
  (notification-type (string-ascii 30))
  (message (string-ascii 300)))
  (let ((incident (map-get? incident-reports { incident-id: incident-id })))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-some (map-get? authorized-investigators { investigator: tx-sender }))) ERR-NOT-AUTHORIZED)
    (asserts! (is-some incident) ERR-INCIDENT-NOT-FOUND)

    (map-set incident-notifications
      { incident-id: incident-id, recipient: recipient }
      {
        notification-type: notification-type,
        message: message,
        sent-date: block-height,
        acknowledged: false,
        acknowledgment-date: none
      }
    )
    (ok true)
  )
)

;; Acknowledge notification
(define-public (acknowledge-notification (incident-id uint))
  (let ((notification (map-get? incident-notifications { incident-id: incident-id, recipient: tx-sender })))
    (asserts! (is-some notification) ERR-INCIDENT-NOT-FOUND)

    (map-set incident-notifications
      { incident-id: incident-id, recipient: tx-sender }
      (merge (unwrap-panic notification)
        {
          acknowledged: true,
          acknowledgment-date: (some block-height)
        }
      )
    )
    (ok true)
  )
)

;; Update incident status
(define-public (update-incident-status (incident-id uint) (new-status (string-ascii 20)))
  (let ((incident (map-get? incident-reports { incident-id: incident-id })))
    (asserts! (or (is-eq tx-sender (var-get contract-owner))
                  (is-eq (some tx-sender) (get assigned-investigator (unwrap-panic incident)))) ERR-NOT-AUTHORIZED)
    (asserts! (is-some incident) ERR-INCIDENT-NOT-FOUND)

    (map-set incident-reports
      { incident-id: incident-id }
      (merge (unwrap-panic incident) { status: new-status })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get incident report
(define-read-only (get-incident-report (incident-id uint))
  (map-get? incident-reports { incident-id: incident-id })
)

;; Get investigation details
(define-read-only (get-investigation (incident-id uint))
  (map-get? incident-investigations { incident-id: incident-id })
)

;; Get recall information
(define-read-only (get-recall (recall-id uint))
  (map-get? product-recalls { recall-id: recall-id })
)

;; Get notification
(define-read-only (get-notification (incident-id uint) (recipient principal))
  (map-get? incident-notifications { incident-id: incident-id, recipient: recipient })
)

;; Get investigator authorization
(define-read-only (get-investigator-auth (investigator principal))
  (map-get? authorized-investigators { investigator: investigator })
)

;; Check if investigator is authorized
(define-read-only (is-authorized-investigator (investigator principal))
  (match (map-get? authorized-investigators { investigator: investigator })
    auth-data (get active auth-data)
    false
  )
)

;; Get incident severity
(define-read-only (get-incident-severity (incident-id uint))
  (match (map-get? incident-reports { incident-id: incident-id })
    incident-data (some (get severity incident-data))
    none
  )
)

;; Check if product is under recall
(define-read-only (is-product-recalled (product-id uint))
  ;; This is a simplified check - in practice, you'd need to iterate through recalls
  ;; For now, we'll return false as a placeholder
  false
)

;; Get next incident ID
(define-read-only (get-next-incident-id)
  (var-get next-incident-id)
)

;; Get next recall ID
(define-read-only (get-next-recall-id)
  (var-get next-recall-id)
)
