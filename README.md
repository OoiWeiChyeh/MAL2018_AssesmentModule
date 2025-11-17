# **README – MAL2018 (Information Management & Retrieval)**

### *TrailService Micro-Service*

# TrailService Micro-Service  
MAL2018 – Information Management and Retrieval  
Author: OOI WEI CHYEH (BSCS2509254)

## 1. Introduction
This repository documents the analysis, design, and initial implementation stages for the TrailService micro-service. The service is responsible for managing trail information, location points, and ownership details as part of a wider well-being trail application. The focus is on producing a clear and reliable data structure supported by secure and maintainable SQL operations.

The repository reflects the required deliverables for the MAL2018 coursework, demonstrating the progression from problem analysis to a working relational design.

## 2. Scope of Work
The work presented includes:

- A complete normalisation process (UNF to 3NF)
- A partial ERD derived from the normalised relations
- A final ERD refined through additional assumptions
- SQL implementation for schema `CW1`, covering:
  - Table creation
  - Sample data insertion
  - A combined view for trails and locations
  - CRUD stored procedures
  - A trigger for audit logging
- Evidence showing successful execution of SQL components
- A basic folder structure for the API to be developed in CW2

Each component is presented to demonstrate accuracy, clarity, and a consistent design approach.

## 3. Repository Structure
```

documentation/
normalisation/
erd/
design_rationale.md
sql/
cw1/
evidence/
api/
skeleton/
README.md

```

This structure separates analytical documents, SQL work, and early API preparation, making the development process transparent and easy to review.

## 4. Design Highlights
### 4.1 Normalisation
The normalisation work ensures the database design avoids redundancy and update anomalies. All relations were examined for functional dependencies, leading to a set of 3NF tables with clear primary and foreign keys.

### 4.2 Entity Relationship Diagrams
Two ERDs are included:
- A partial ERD generated directly from the 3NF relations  
- A final ERD incorporating assumptions regarding ownership, trail structure, and location ordering

The diagrams support the logical structure of the TrailService and justify the chosen relationships.

### 4.3 SQL Schema and Functionality
The SQL scripts demonstrate:
- Correct implementation of the schema
- Clean handling of trail and location data
- Secure data manipulation through stored procedures
- Controlled visibility through a structured view
- Audit support with a trail creation trigger

These features contribute to a robust foundation for the micro-service.

## 5. Security and Integrity Considerations
The design choices reflect a security-aware approach suitable for a cybersecurity programme. Key considerations include:
- Avoiding duplication of sensitive information
- Maintaining referential integrity throughout all relations
- Restricting operations to stored procedures rather than direct table access
- Using triggers to support accountability and traceability
- Preparing the API structure for secure handling of external requests in CW2

## 6. Academic Context
All work contained in this repository is produced for the module MAL2018 – Information Management and Retrieval. The documentation and implementation demonstrate analytical reasoning, accurate application of relational theory and preparation for practical micro-service development.

Any assistance obtained from AI tools is formally declared in the final written submission.

## 7. Maintainer
OOI WEI CHYEH  
BSc (Hons) Cyber Security  
University of Plymouth
