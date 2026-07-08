default rel

extern printf
global main

section .data
    title_msg db "Mini Lunar Lander Autopilot - Fixed Point ASM", 10, 0
    line_msg  db "------------------------------------------------", 10, 0

    fmt_status db "t=%llds | altitude=%lld m | velocity=%lld m/s", 10, 0
    fmt_engine db "        fuel=%lld kg | engine=%s", 10, 0

    fmt_landed db 10, "RESULT: Safe landing achieved.", 10, 0
    fmt_crashed db 10, "RESULT: Crash landing. Velocity too high.", 10, 0
    fmt_timeout db 10, "RESULT: Simulation timeout.", 10, 0

    engine_on  db "ON", 0
    engine_off db "OFF", 0

    ; Fixed-point scale:
    ; Distance and velocity are stored in millimeters.
    scale dq 1000

    ; Mission state
    time_s      dq 0
    altitude_mm dq 15000000 ; 15000 m
    velocity_mm dq -50000 ; -50 m/s, negative means falling downward
    fuel_kg     dq 120

    ; Physics constants
    gravity_mm      dq -1620 ; Moon gravity = -1.62 m/s^2
    thrust_mm       dq 60000; Engine thrust acceleration = +4.00 m/s^2
    burn_kg         dq 4; Fuel burned per second when engine is ON

    ; Autopilot rule:
    ; Turn engine ON if velocity is lower than -20 m/s.
    engine_limit_mm dq -60000

    ; Landing rule:
    ; Safe if final velocity is at least -5 m/s.
    safe_vel_mm dq -5000

    max_time dq 3000
    print_interval dq 10

section .bss
    altitude_m resq 1
    velocity_m resq 1
    net_accel_mm resq 1
    engine_ptr resq 1

section .text
main:
    sub rsp, 40

    lea rcx, [title_msg]
    call printf

    lea rcx, [line_msg]
    call printf

simulation_loop:
    ; Default: engine OFF
    lea rax, [engine_off]
    mov qword [engine_ptr], rax

    ; Default acceleration = gravity
    mov rax, qword [gravity_mm]
    mov qword [net_accel_mm], rax

    ; If fuel <= 0, engine cannot turn on
    cmp qword [fuel_kg], 0
    jle apply_physics

    ; If velocity >= -20 m/s, falling is slow enough, keep engine OFF
    mov rax, qword [velocity_mm]
    cmp rax, qword [engine_limit_mm]
    jge apply_physics

    ; Otherwise, turn engine ON
    mov rax, qword [gravity_mm]
    add rax, qword [thrust_mm]
    mov qword [net_accel_mm], rax

    ; Burn fuel
    mov rax, qword [fuel_kg]
    sub rax, qword [burn_kg]

    ; Clamp fuel to zero
    cmp rax, 0
    jge fuel_ok
    xor rax, rax

fuel_ok:
    mov qword [fuel_kg], rax

    lea rax, [engine_on]
    mov qword [engine_ptr], rax

apply_physics:
    ; velocity = velocity + acceleration
    ; dt = 1 second, so no multiplication needed
    mov rax, qword [velocity_mm]
    add rax, qword [net_accel_mm]
    mov qword [velocity_mm], rax

    ; altitude = altitude + velocity
    mov rax, qword [altitude_mm]
    add rax, qword [velocity_mm]

    ; If altitude goes below zero, clamp it to zero
    cmp rax, 0
    jge altitude_ok
    xor rax, rax

altitude_ok:
    mov qword [altitude_mm], rax

    ; time = time + 1
    inc qword [time_s]

    ; Print only every 10 seconds, or at touchdown
    cmp qword [altitude_mm], 0
    je print_status

    mov rax, qword [time_s]
    cqo
    idiv qword [print_interval]
    cmp rdx, 0
    jne check_end_conditions

print_status:
    ; altitude_m = altitude_mm / 1000
    mov rax, qword [altitude_mm]
    cqo
    idiv qword [scale]
    mov qword [altitude_m], rax

    ; velocity_m = velocity_mm / 1000
    mov rax, qword [velocity_mm]
    cqo
    idiv qword [scale]
    mov qword [velocity_m], rax

    ; printf("t=%llds | altitude=%lld m | velocity=%lld m/s")
    lea rcx, [fmt_status]
    mov rdx, qword [time_s]
    mov r8, qword [altitude_m]
    mov r9, qword [velocity_m]
    call printf

    ; printf("fuel=%lld kg | engine=%s")
    lea rcx, [fmt_engine]
    mov rdx, qword [fuel_kg]
    mov r8, qword [engine_ptr]
    call printf

check_end_conditions:
    ; If altitude <= 0, touchdown happened
    cmp qword [altitude_mm], 0
    jle touchdown

    ; If time >= max_time, stop
    mov rax, qword [time_s]
    cmp rax, qword [max_time]
    jl simulation_loop

    lea rcx, [fmt_timeout]
    call printf
    jmp end_program

touchdown:
    ; If velocity < safe velocity, crash
    mov rax, qword [velocity_mm]
    cmp rax, qword [safe_vel_mm]
    jl crash_landing

safe_landing:
    lea rcx, [fmt_landed]
    call printf
    jmp end_program

crash_landing:
    lea rcx, [fmt_crashed]
    call printf

end_program:
    xor eax, eax
    add rsp, 40
    ret