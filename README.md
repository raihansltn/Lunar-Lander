# Lunar Lander Simulation in x86-64 Assembly (NASM)

A simple **Lunar Lander** simulation written in **x86-64 Assembly (NASM)** for Windows.

The project demonstrates how early aerospace-style numerical simulations can be implemented using only integer arithmetic (fixed-point representation), similar to the constraints faced by early NASA guidance computers.

---

## Features

- Fixed-point arithmetic (no floating-point instructions)
- Discrete-time physics simulation
- Lunar gravity
- Automatic engine control
- Fuel consumption
- Safe landing / crash detection
- Console output

---

## Simulation Model

The simulation updates the lander's state every **1 second**.

State variables:

- Altitude
- Velocity
- Fuel
- Engine state
- Time

The engine automatically turns on whenever the descent speed exceeds a predefined threshold.

---

## Physics

The simulator uses the following equations.

### Engine Decision

```text
if fuel > 0 AND velocity < engine_limit
    engine = ON
else
    engine = OFF
```

---

### Acceleration

```text
acceleration = gravity + engine × thrust
```

where

```text
engine = 0 or 1
```

---

### Fuel

```text
fuel = max(0, fuel - burn_rate)
```

---

### Velocity

```text
velocity = velocity + acceleration
```

---

### Altitude

```text
altitude = max(0, altitude + velocity)
```

---

## Fixed Point Representation

Instead of floating-point numbers, every value is multiplied by **1000**.

Example:

| Real Value | Stored Value |
|------------|-------------:|
| 300.0 m | 300000 |
| -20.0 m/s | -20000 |
| 2.38 m/s² | 2380 |
| -1.62 m/s² | -1620 |

This technique was commonly used in early embedded systems and spacecraft guidance computers.

---

## Project Structure

```
.
├── lander.asm
├── README.md
├── LICENSE
└── docs/
    └── Lander.pdf
```

---

## Requirements

- NASM
- GCC (MinGW-w64)
- Windows

Example installation using MSYS2:

```bash
pacman -S mingw-w64-ucrt-x86_64-toolchain
pacman -S mingw-w64-ucrt-x86_64-nasm
```

---

## Build

Assemble

```bash
nasm -f win64 lander.asm -o lander.obj
```

Link

```bash
gcc lander.obj -o lander.exe
```

Run

```bash
./lander.exe
```

---

## Example Output

```text
Time : 56 s
Altitude : 0.00 m
Velocity : -2.72 m/s
Fuel : 92 kg

SAFE LANDING
```

---

## Program Flow

```text
Initialize variables
        │
        ▼
Print current state
        │
        ▼
Engine ON?
        │
        ├── Yes
        │     │
        │     ▼
        │  Consume fuel
        │
        ▼
Compute acceleration
        │
        ▼
Update velocity
        │
        ▼
Update altitude
        │
        ▼
Altitude <= 0 ?
        │
        ├── No ────────────────┐
        │                      │
        ▼                      │
Increase time                 │
        │                      │
        └──────────────────────┘
        │
        ▼
Landing
        │
        ▼
Safe or Crash
```

---

## References

- Apollo Guidance Computer Documentation
- NASA Lunar Module Descent Guidance
- Intel® 64 and IA-32 Architectures Software Developer Manual
- NASM Documentation

---

## Author

(**Raihan Sultan Basuki**)[https://raihansltn.github.io]

---

## License

This project is released under the MIT License.