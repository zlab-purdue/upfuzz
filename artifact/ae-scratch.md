# Reproducing the Results from Scratch

To streamline the artifact evaluation (AE) process, we provide pre-built instrumented binaries (Step 1) and pre-recorded bug-triggering traces, enabling a push-button evaluation workflow.  
Reviewers may also reproduce all experiments entirely from scratch; however, this requires a substantial amount of computation time.

All experiments were originally conducted in parallel using a large number of servers.

---

## 1. Creating the Instrumented Binary

### 1.1 Source Code Analysis

- Repository: `vasco`

### 1.2 Source Code Instrumentation

- Repository: `dinv-runtime`

---

## 2. Fuzz Testing

- Repositories: `upfuzz`, `ssg-runtime`

### Reproducing Tables 2 and 3

**Expected time:** approximately **450 machine-days** (270 + 180).

For each version pair, we configure UpFuzz to test under multiple settings and repeat each experiment three times.  
Scripts are provided to automatically check whether a failure is successfully triggered.

---

### Reproducing Figure 14

**Expected time:** approximately **27 machine-days**.

We configure UpFuzz to run in the state-exploration mode.

---

### Reproducing Table 4

This experiment follows the same procedure described in `ae.md`.
