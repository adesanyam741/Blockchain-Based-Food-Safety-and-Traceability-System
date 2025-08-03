# Blockchain-Based Food Safety and Traceability System

## Overview

This system provides a comprehensive blockchain-based solution for food safety and traceability in local farmers markets. It ensures transparency, safety, and trust between farmers, vendors, and consumers through five interconnected smart contracts.

## System Components

### 1. Farmer Certification Verification Contract (`farmer-certification.clar`)
- Validates organic, pesticide-free, and other farming certifications
- Manages certification authorities and their credentials
- Tracks certification expiration dates and renewal status
- Provides verification mechanisms for market vendors

### 2. Product Origin Tracking Contract (`product-origin.clar`)
- Records detailed information about where each product was grown and harvested
- Tracks farm locations, harvest dates, and batch information
- Links products to certified farmers
- Maintains immutable harvest records

### 3. Temperature Monitoring Contract (`temperature-monitoring.clar`)
- Ensures perishable foods are kept at safe temperatures during transport
- Records temperature readings at regular intervals
- Alerts when temperature thresholds are exceeded
- Maintains cold chain integrity documentation

### 4. Allergen Labeling Verification Contract (`allergen-labeling.clar`)
- Provides accurate allergen information for consumers with food sensitivities
- Manages comprehensive allergen databases
- Verifies product allergen declarations
- Enables consumer safety queries

### 5. Food Safety Incident Reporting Contract (`food-safety-incidents.clar`)
- Tracks and responds to reports of foodborne illness or contamination
- Enables rapid product recalls when necessary
- Maintains incident investigation records
- Provides transparency in safety responses

## Key Features

- **Immutable Records**: All data is stored on the blockchain for permanent traceability
- **Real-time Verification**: Instant verification of certifications and safety status
- **Consumer Protection**: Comprehensive allergen and safety information
- **Regulatory Compliance**: Meets food safety regulatory requirements
- **Decentralized Trust**: No single point of failure or control

## Data Types

### Farmer Profile
- Principal address
- Farm name and location
- Certification types and expiration dates
- Contact information

### Product Record
- Unique product ID
- Origin farm information
- Harvest date and batch number
- Temperature requirements
- Allergen information

### Temperature Log
- Product ID reference
- Timestamp
- Temperature reading
- Location/transport stage
- Compliance status

### Incident Report
- Incident ID
- Affected products
- Severity level
- Investigation status
- Resolution actions

## Usage Workflow

1. **Farmer Registration**: Farmers register and submit certifications
2. **Product Registration**: Products are registered with origin and safety data
3. **Transport Monitoring**: Temperature is monitored during transport
4. **Market Sales**: Consumers can verify all product information
5. **Incident Response**: Any safety issues are immediately tracked and addressed

## Security Features

- Multi-signature requirements for critical operations
- Role-based access control
- Immutable audit trails
- Automated compliance checking
- Emergency response mechanisms

## Benefits

- **For Farmers**: Verified credentials and product authenticity
- **For Vendors**: Reliable supplier verification and compliance tracking
- **For Consumers**: Complete transparency and safety assurance
- **For Regulators**: Comprehensive oversight and rapid incident response

## Getting Started

1. Deploy all five contracts to the Stacks blockchain
2. Register certification authorities
3. Onboard farmers with their certifications
4. Begin product registration and monitoring
5. Enable consumer access to verification tools

## Testing

The system includes comprehensive tests for all contracts using Vitest, covering:
- Contract deployment and initialization
- Farmer registration and certification
- Product tracking and verification
- Temperature monitoring and alerts
- Incident reporting and response
- Access control and security features

## Compliance

This system is designed to meet or exceed:
- FDA food safety regulations
- USDA organic certification requirements
- Local health department standards
- Consumer protection laws
- Data privacy regulations
