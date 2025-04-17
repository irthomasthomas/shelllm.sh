irthomasthomas: Generate a markdown doc with examples of every type of mermaid diagram supported.

GitHub Copilot: # Mermaid Diagram Examples

This document provides examples of all supported Mermaid diagram types with sample code and rendered output.

## 1. Flowchart

Flowcharts are diagrams that represent workflows or processes.

```mermaid
graph TD
    A[Start] --> B{Is it working?}
    B -->|Yes| C[Great!]
    B -->|No| D[Debug]
    D --> B
```

## 2. Sequence Diagram

Sequence diagrams show how processes operate with one another and in what order.

```mermaid
sequenceDiagram
    participant Alice
    participant Bob
    Alice->>Bob: Hello Bob, how are you?
    Bob-->>Alice: I'm good thanks!
    Alice->>Bob: Great to hear!
```

## 3. Class Diagram

Class diagrams show the structure of a system by displaying classes, attributes, methods, and relationships.

```mermaid
classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal <|-- Zebra
    Animal : +int age
    Animal : +String gender
    Animal: +isMammal()
    Animal: +mate()
    class Duck{
      +String beakColor
      +swim()
      +quack()
    }
```

## 4. State Diagram

State diagrams describe the behavior of a system, showing state transitions.

```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> [*]
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

## 5. Entity Relationship Diagram

ER diagrams show relationships between entities in a database.

```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    CUSTOMER }|..|{ DELIVERY-ADDRESS : uses
```

## 6. User Journey Diagram

User journey diagrams visualize the user's experience with a product or service.

```mermaid
journey
    title My working day
    section Go to work
      Make tea: 5: Me
      Go upstairs: 3: Me
      Do work: 1: Me, Cat
    section Go home
      Go downstairs: 5: Me
      Sit down: 5: Me
```

## 7. Gantt Chart

Gantt charts illustrate project schedules with tasks displayed against time.

```mermaid
gantt
    title Project Schedule
    dateFormat  YYYY-MM-DD
    section Design
    Task 1           :a1, 2023-01-01, 7d
    Task 2           :after a1, 5d
    section Development
    Task 3           :2023-01-12, 9d
    Task 4           :2023-01-20, 5d
```

## 8. Pie Chart

Pie charts represent data as slices of a circle.

```mermaid
pie
    title Distribution of Time
    "Work" : 40
    "Eat" : 10
    "Sleep" : 30
    "Entertainment" : 20
```

## 9. Git Graph

Git graphs visualize Git commit history and branching.

```mermaid
gitGraph
    commit
    branch develop
    checkout develop
    commit
    commit
    checkout main
    merge develop
    commit
    commit
```

## 10. Requirement Diagram

Requirement diagrams document system requirements and their relationships.

```mermaid
requirementDiagram
    requirement test_req {
        id: 1
        text: The system shall do something
        risk: high
        verifymethod: test
    }
    element test_entity {
        type: simulation
    }
    test_entity - satisfies -> test_req
```

## 11. C4 Diagram

C4 diagrams model the architecture of software systems.

```mermaid
C4Context
    title System Context diagram for Internet Banking System
    Enterprise_Boundary(b0, "BankBoundary") {
      Person(customer, "Banking Customer", "A customer of the bank")
      System(banking_system, "Internet Banking System", "Allows customers to view account balances and make payments")
    }
    System_Ext(mail_system, "E-mail system", "The internal Microsoft Exchange e-mail system")
    Rel(customer, banking_system, "Uses")
    Rel(banking_system, mail_system, "Sends e-mails", "SMTP")
```

## 12. Mindmap

Mindmaps are diagrams used to visually organize information.

```mermaid
mindmap
  root((Project))
    Design
      UI
      UX
    Development
      Frontend
      Backend
      Database
    Testing
      Unit Tests
      Integration Tests
    Deployment
```

## 13. Timeline

Timelines visualize a chronological sequence of events.

```mermaid
timeline
    title Project Timeline
    section Planning
        Design            : 2023-01-01 : 2023-01-15
        Requirements      : 2023-01-10 : 2023-01-20
    section Implementation
        Development       : 2023-01-21 : 2023-02-20
        Testing           : 2023-02-15 : 2023-03-01
    section Launch
        Deployment        : 2023-03-01 : 2023-03-05
        Review            : 2023-03-05 : 2023-03-10
```

## 14. Quadrant Chart

Quadrant charts divide data into four sections for analysis.

```mermaid
quadrantChart
    title Prioritization Matrix
    x-axis Low Impact --> High Impact
    y-axis Low Effort --> High Effort
    quadrant-1 Quick Wins
    quadrant-2 Major Projects
    quadrant-3 Time Wasters
    quadrant-4 Fill-ins
    Feature A: [0.1, 0.6]
    Feature B: [0.5, 0.2]
    Feature C: [0.7, 0.7]
    Feature D: [0.3, 0.9]
```

## 15. Sankey Diagram

Sankey diagrams visualize flow and quantities in a system.

```mermaid
sankey-beta
    Office Energy,Electricity,15
    Office Energy,Natural Gas,5
    Electricity,Lighting,5
    Electricity,HVAC,7
    Electricity,Computing,3
    Natural Gas,Heating,5
```

## 16. Block Diagram
Block diagrams represent systems and their components.

```mermaid
block-beta
    columns 3
    space:1 a["Database"]
    space b["API Server"]
    space:1 c["Web Client"]
    a --> b --> c
```

## 17. Flowchart with Subgraphs
Flowcharts with subgraphs allow for grouping related nodes.

```mermaid
graph TD
    subgraph Backend
        A[API] --> B[Database]
        B --> C[Cache]
    end
    subgraph Frontend
        D[UI Components] --> E[State Management]
    end
    A --> D
```

## 18. XY Chart
XY charts visualize data points in a two-dimensional space.

```mermaid
xychart-beta
    title "Sales Revenue"
    x-axis [jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec]
    y-axis "Revenue (in $)" 4000 --> 11000
    bar [5000, 6000, 7500, 8200, 9500, 10500, 11000, 10200, 9200, 8500, 7000, 6000]
    line [5000, 6000, 7500, 8200, 9500, 10500, 11000, 10200, 9200, 8500, 7000, 6000]
```

## 19. Code Smell Visualization

Code smell visualizations highlight problematic areas in code using Mermaid diagrams. These diagrams can help developers understand structural issues and areas for improvement.

### Example: Class Diagram with Code Smells

```mermaid
classDiagram
    class User {
        - String name
        - String email
        + login()
        + logout()
    }
    class UserManager {
        - List<User> users
        + addUser(User user)
        + removeUser(User user)
    }
    UserManager --> User : manages

    %% Highlighting code smells
    class UserManager {
        %% Code Smell: God Class
        %% Reason: Too many responsibilities
    }
```

### Example: Flowchart with Code Smells

```mermaid
graph TD
    A[Start] --> B{Is input valid?}
    B -- Yes --> C[Process Input]
    B -- No --> D[Error]
    C --> E[End]

    %% Highlighting code smells
    B{Is input valid?}:::code-smell
    classDef code-smell fill:#f96,stroke:#333,stroke-width:2px;
    %% Code Smell: Complex Conditional Logic
    %% Reason: Difficult to maintain and test
```

### Example: State Diagram with Code Smells

```mermaid
stateDiagram-v2
    [*] --> Idle
    Idle --> Processing : start()
    Processing --> Idle : stop()
    Processing --> Error : fail()
    Error --> [*]

    %% Highlighting code smells
    state Processing {
        %% Code Smell: Long Method
        %% Reason: Too many transitions
    }
```