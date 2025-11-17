# **README — MAL2018 (Information Management & Retrieval)**

### **TrailService Micro-Service Implementation**

```md
# TrailService Micro-Service

MAL2018 – Information Management & Retrieval  
Author: [Your Full Name]

## 1. Overview

This repository contains the design, data modelling, SQL implementation, and API preparation for the **TrailService** micro-service, part of a larger well-being trail application.  
My role is to design and implement the section responsible for:

- Managing trails
- Storing location points
- Linking trails to their owners
- Providing secure and structured access through an API

This project combines database modelling practices with secure API design, reflecting the principles covered in the module.

---

## 2. Purpose of This Commit

This initial commit includes all early-stage deliverables required for CW1, focusing on data analysis, schema design, and database implementation before writing the micro-service code.

The commit contains:

- Full normalisation steps from UNF → 3NF
- A partial ERD derived from the normalised relations
- A final ERD refined through additional assumptions
- SQL scripts for the CW1 schema
- Evidence screenshots demonstrating successful table creation, sample data, views, triggers, and stored procedures
- A scaffold for the TrailService Python API

The structure and clarity mirror industry standards for building secure, maintainable micro-services.

---

## 3. Repository Structure
```

<!--
documentation/
├── normalisation/
├── erd/
└── design_rationale.md
sql/
├── cw1/
└── evidence/
api/
└── skeleton/
.gitignore
README.md

```

Each directory corresponds directly to an assessment requirement and helps track the progression toward the final CW2 micro-service implementation.
-->

---

## 4. Key Work Included in This Phase

### ✔ Normalisation (UNF → 3NF)

A step-by-step breakdown showing:

- Removal of repeating groups
- Establishing atomic values
- Eliminating partial and transitive dependencies
- Final 3NF relations with clear reasoning

This ensures that stored data remains consistent and secure.

### ✔ Entity Relationship Diagrams

Two forms are included:

1. **Partial ERD** (from normalised tables)
2. **Final ERD** (after merging with derived design requirements)

All relationships use clear naming conventions, primary keys, and foreign key constraints.

### ✔ SQL Implementation – Schema `CW1`

Includes:

- Table creation
- Sample data
- A view combining trail and location information
- CRUD stored procedures
- A trigger to log trail creation
- Demonstration screenshots showing results

### ✔ API Skeleton

A minimal FastAPI/Flask-style structure to prepare for CW2, including:

- Project folders
- Placeholder routes
- Draft Swagger definition file

---

## 5. Security and Data Integrity Considerations

Although full implementation appears in CW2, data protection thinking already guides this stage:

- Sensitive information is not duplicated; authentication stays with an external service
- Database structure promotes consistent updates
- Stored procedures reduce the risk of injection
- Views and triggers provide controlled visibility and auditing

This aligns with secure development practices emphasised within cybersecurity.

---

## 6. Academic Note

This repository reflects the expected progression from modelling → database implementation → API preparation.  
All development decisions are justified in the included markdown files.

Any AI assistance is documented in the final report according to module requirements.

---

## 7. Contact

Maintained by:  
**[OOI WEI CHYEH, BSCS2509254] **

```

```
