# Ledger

## Table of Contents

- [Installation](#installation)
- [Running](#running)

## Installation

To get started with this project, follow these steps:

1. **Install Dependencies:**
   Ensure you have Erl installed (Erl 1.16 or higher). Then install the required packages:
   ```sh
   mix deps.get
   ```

## Running

Once your environment is set up, you can run the project using the following commands:

1. **Docker Compose Postgres:**
   ```sh
   docker compose up
   ```

2. **Compile the project:**
   ```sh
   mix build
   ```

3. **Run Binary:**
   ```sh
   ./ledger <command> <args>

