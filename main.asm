GL_ARRAY_BUFFER equ 0x8892
GL_STATIC_DRAW equ 0x88E4
GL_FLOAT equ 0x1406
GL_TRIANGLES equ 0x0004
GL_COLOR_BUFFER_BIT equ 0x4000

section .data
    window_title db "Triangle 243", 0

    clear_red dd 0.1
    clear_green dd 0.2
    clear_blue dd 0.8
    clear_alpha dd 1.0

    vertex_shader_src:
        db "#version 330 core", 10 ;use GLSL 3.30 core
        db "layout (location = 0) in vec2 aPos;", 10
        db "void main()", 10
        db "{", 10
        db "    gl_Position = vec4(aPos, 0.0, 1.0);", 10 ;apos.x and y, 0.0 is z, 1.0 is w
        db "}", 10
        db 0

    fragment_shader_src:
        db "#version 330 core", 10
        db "out vec4 FragColor;", 10
        db "void main()", 10
        db "{", 10
        db "    FragColor = vec4(1.0, 0.5, 0.1, 1.0);", 10
        db "}", 10
        db 0

    vertices:
        dd 0.0, 0.5
        dd -0.5, -0.5
        dd 0.5, -0.5
    

    name_glCreateShader db "glCreateShader", 0
    name_glShaderSource db "glShaderSource", 0
    name_glCompileShader db "glCompileShader", 0
    name_glGetShaderiv db "glGetShaderiv", 0
    name_glCreateProgram db "glCreateProgram", 0
    name_glAttachShader db "glAttachShader", 0
    name_glLinkProgram db "glLinkProgram", 0
    name_glGetProgramiv db "glGetProgramiv", 0
    name_glGenBuffers db "glGenBuffers", 0
    name_glBindBuffer db "glBindBuffer", 0
    name_glBufferData db "glBufferData", 0
    name_glGenVertexArrays db "glGenVertexArrays", 0
    name_glBindVertexArray db "glBindVertexArray", 0
    name_glVertexAttribPointer db "glVertexAttribPointer", 0
    name_glEnableVertexAttribArray db "glEnableVertexAttribArray", 0
    name_glUseProgram db "glUseProgram", 0
    name_glDrawArrays db "glDrawArrays", 0
    

    msg_shader_ok db "Shader compiled", 10, 0
    msg_shader_fail db "Shader failed to compile", 10, 0
    program_status_id db "Program status ID: %d", 10, 0


    ; debugging tools
    a db "a", 10, 0
    b db "b", 10, 0
    c db "c", 10, 0
    d db "d", 10, 0
    e db "e", 10, 0
    error_format db "GLFW error %d: %s", 10, 0
    no_error_msg db "No GLFW error details available", 10, 0
    version_format db "OpenGL version: %s", 10, 0
    msg_func_ok db "Functions loaded", 10, 0
    msg_func_fail db "Failed to load function", 10, 0
    msg_create_program_fail db "Failed to create program", 10, 0
    msg_initialisation_fail db "Failed to initialise GLAD", 10, 0

section .bss
    window_ptr resq 1
    error_description resq 1
    ptr_glGenVertexArrays resq 1 ;ptrs are the actual function itself, without ptr is the actual object itself
    ptr_glCreateShader resq 1
    ptr_glShaderSource resq 1
    ptr_glCompileShader resq 1
    ptr_glGetShaderiv resq 1
    ptr_glCreateProgram resq 1
    ptr_glAttachShader resq 1
    ptr_glLinkProgram resq 1
    ptr_glGetProgramiv resq 1
    ptr_glGenBuffers resq 1
    ptr_glBindBuffer resq 1
    ptr_glBufferData resq 1
    ptr_glBindVertexArray resq 1
    ptr_glVertexAttribPointer resq 1
    ptr_glEnableVertexAttribArray resq 1
    ptr_glUseProgram resq 1
    ptr_glDrawArrays resq 1
    vertex_shader resd 1 ;4 bytes
    vertex_source_ptr resq 1 ;8 bytes
    fragment_shader resd 1
    fragment_source_ptr resq 1
    program resq 1
    program_status resd 1
    shader_status resd 1
    vbo resd 1
    vao resd 1


section .text
    global main

    extern printf

    extern glfwInit ;initialise glfw to use glfw. returns 1 (in eax) if succeed, 0 if fail
    extern glfwGetProcAddress
    extern glfwWindowHint ;what kind of window to make. two params, hint (which setting to configure) and value. 0x00022001 is the identifier for GLFW_CLIENT_API. value of zero means GLFW_NO_API, telling the system not to create a window
    extern glfwMakeContextCurrent
    extern glfwCreateWindow ;width height title monitor share. returns GLFWwindow*, a pointer to an obj. if succeed, pointer is in rax. if fail, rax is 0
    extern glfwWindowShouldClose ;one param, the pointer to the window
    extern glfwPollEvents ;processes pending events, no args and returns
    extern glfwSwapBuffers
    extern glfwDestroyWindow ;one param, window pointer. cleanup before exiting. ptr is invalid after cleanup
    extern glfwTerminate ;no params, exit glfw
    extern glfwGetError

    extern glGetString
    extern glClearColor ;red green blue alpha/opacity, all floats. because its floats, it goes into xmm
    extern glClear

main:
    sub rsp, 40

    call glfwInit
    test eax, eax
    jz init_failed

    mov ecx, 0x00022002 ;code for req opengl, GLFW_CONTEXT_VERSION_MAJOR
    mov edx, 4 ;opengl major version
    call glfwWindowHint

    mov ecx, 0x00022003 ;GLFW_CONTEXT_VERSION_MINOR
    mov edx, 6 
    call glfwWindowHint

    ;requests core profile
    mov ecx, 0x00022008 ;GLFW_OPENGL_PROFILE
    mov edx, 0x00032001 ;GLFW_OPENGL_CORE_PROFILE
    call glfwWindowHint

    mov ecx, 800
    mov edx, 600
    lea r8, [rel window_title]
    xor r9d, r9d
    mov qword [rsp+32], 0
    call glfwCreateWindow

    test rax, rax
    jz create_failed

    mov [rel window_ptr], rax ;pointer is stored in rax, so save to window_ptr

    mov rcx, [rel window_ptr]
    call glfwMakeContextCurrent ;subsequent opengl calls should operate on this windows context

    lea rcx, [rel name_glGenVertexArrays]
    call glfwGetProcAddress ;returned function address stored in rax

    test rax, rax
    jz func_load_failed

    mov [rel ptr_glGenVertexArrays], rax

    ; load all functions, because GLAD was not used
    ; load glCreateShader
    lea rcx, [rel name_glCreateShader]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glCreateShader], rax

    ; load glShaderSrc
    lea rcx, [rel name_glShaderSource]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glShaderSource], rax

    ; load glCompileShader
    lea rcx, [rel name_glCompileShader]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glCompileShader], rax

    ; load glGetShaderiv
    lea rcx, [rel name_glGetShaderiv]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glGetShaderiv], rax

    lea rcx, [rel name_glCreateProgram]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glCreateProgram], rax

    lea rcx, [rel name_glAttachShader]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glAttachShader], rax

    lea rcx, [rel name_glLinkProgram]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glLinkProgram], rax

    lea rcx, [rel name_glGetProgramiv]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glGetProgramiv], rax

    lea rcx, [rel name_glGenBuffers]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glGenBuffers], rax

    lea rcx, [rel name_glBindBuffer]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glBindBuffer], rax

    lea rcx, [rel name_glBufferData]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glBufferData], rax

    lea rcx, [rel name_glBindVertexArray]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glBindVertexArray], rax

    lea rcx, [rel name_glVertexAttribPointer]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glVertexAttribPointer], rax

    lea rcx, [rel name_glEnableVertexAttribArray]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glEnableVertexAttribArray], rax

    lea rcx, [rel name_glUseProgram]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glUseProgram], rax

    lea rcx, [rel name_glDrawArrays]
    call glfwGetProcAddress
    test rax, rax
    jz func_load_failed
    mov [rel ptr_glDrawArrays], rax

    lea rcx, [rel msg_func_ok]
    call printf

    jmp func_load_done

func_load_failed:
    lea rcx, [rel msg_func_fail]
    call printf

    mov eax, 1
    jmp exit

func_load_done:
    movss xmm0, [rel clear_red]
    movss xmm1, [rel clear_green]
    movss xmm2, [rel clear_blue]
    movss xmm3, [rel clear_alpha]
    call glClearColor ;sets the colour when the colour buffers are cleared

    ;create vertex shader
    mov ecx, 0x00008B31
    call [rel ptr_glCreateShader]

    test eax, eax
    jz shader_failed

    mov [rel vertex_shader], eax

    lea rax, [rel vertex_shader_src]
    mov [rel vertex_source_ptr], rax

    ;gl shader src (shader, 1, &source_ptr, null)
    mov ecx, [rel vertex_shader]
    mov edx, 1
    lea r8, [rel vertex_source_ptr]
    xor r9d, r9d
    call [rel ptr_glShaderSource]

    ;compile shader

    mov ecx, [rel vertex_shader]
    call [rel ptr_glCompileShader]

    ;get shader iv(shader, gl_compile_status, &status)
    mov ecx, [rel vertex_shader]
    mov edx, 0x00008B81
    lea r8, [rel shader_status]
    call [rel ptr_glGetShaderiv]

    cmp dword [rel shader_status], 0
    je shader_failed

    ;====================================================================================
    ; Create fragment shader
    mov ecx, 0x00008B30 ;GL_FRAGMENT_SHADER
    call [rel ptr_glCreateShader]

    test eax, eax
    jz shader_failed

    mov [rel fragment_shader], eax

    lea rax, [rel fragment_shader_src]
    mov [rel fragment_source_ptr], rax

    ;gl shader src (shader, 1, &source_ptr, null)
    mov ecx, [rel fragment_shader]
    mov edx, 1
    lea r8, [rel fragment_source_ptr]
    xor r9d, r9d
    call [rel ptr_glShaderSource]

    ;compile shader

    mov ecx, [rel fragment_shader]
    call [rel ptr_glCompileShader]

    ;get shader iv(shader, gl_compile_status, &status)
    mov ecx, [rel fragment_shader]
    mov edx, 0x00008B81
    lea r8, [rel shader_status]
    call [rel ptr_glGetShaderiv]

    cmp dword [rel shader_status], 0
    je shader_failed

    lea rcx, [rel msg_shader_ok]
    call printf
    jmp shader_check_done

shader_failed:
    lea rcx, [rel msg_shader_fail]
    call printf

shader_check_done:

    ; GLuint glCreateProgram(void)
    call [rel ptr_glCreateProgram]

    test eax, eax 
    jz .createProgramFail 
    mov [rel program], eax

    ; Vertex shader
    ; glAttachShader(program, vshader)
    mov ecx, [rel program]
    mov edx, [rel vertex_shader]
    call [rel ptr_glAttachShader]

    ; void glLinkProgram(GLuint program);
    mov ecx, [rel program]
    call [rel ptr_glLinkProgram]

    ; void glGetProgramiv(GLuint program, GLenum pname, GLint *params)
    mov ecx, [rel program]
    mov rdx, 0x00008B82 ;GL_LINK_STATUS
    lea r8, [rel program_status]
    call [rel ptr_glGetProgramiv]

    lea rcx, [rel program_status_id]
    mov rdx, [rel program_status]
    call printf

    ; Fragment shader
    ; glAttachShader(program, vshader)
    mov ecx, [rel program]
    mov edx, [rel fragment_shader]
    call [rel ptr_glAttachShader]

    ; void glLinkProgram(GLuint program);
    mov ecx, [rel program]
    call [rel ptr_glLinkProgram]

    ; void glGetProgramiv(GLuint program, GLenum pname, GLint *params)
    mov ecx, [rel program]
    mov rdx, 0x00008B82 ;GL_LINK_STATUS
    lea r8, [rel program_status]
    call [rel ptr_glGetProgramiv]

    lea rcx, [rel program_status_id]
    mov rdx, [rel program_status] ; 1 shows that its success
    call printf

    ;================================================================================

    ; void glGenBuffers(GLsizei n, GLuint *buffers)
    mov ecx, 1 ; Generate one buffer
    lea rdx, [rel vbo] ; vbo where we store the buffer
    call [rel ptr_glGenBuffers]

    ; void glBindBuffer(GLenum target, GLuint buffer)
    mov ecx, GL_ARRAY_BUFFER
    mov rdx, [rel vbo]
    call [rel ptr_glBindBuffer]
    
    ; void glBufferData(GLenum target, GLsizeiptr size, const void *data, GLenum usage)
    mov ecx, GL_ARRAY_BUFFER
    mov rdx, 24 ; triangle 6 floats, each float 4 bytes.
    lea r8, [rel vertices]
    mov r9d, GL_STATIC_DRAW
    call [rel ptr_glBufferData]

    ; void glGenVertexArrays(GLsizei n, GLuint *arrays)
    mov ecx, 1
    lea rdx, [rel vao]
    call [rel ptr_glGenVertexArrays]

    ; void glBindVertexArray(GLuint array)
    mov rcx, [rel vao]
    call [rel ptr_glBindVertexArray]

    ; void glVertexAttribPointer(GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const void *pointer)
    sub rsp, 16

    xor ecx, ecx ; index = 0 because layout(location = 0)
    mov edx, 2 ; 2 components per vertex, default is 4
    mov r8d, GL_FLOAT
    xor r9d, r9d
    mov qword [rsp+32], 8 ; 8 bytes per vertex
    mov qword [rsp+40], 0

    call [rel ptr_glVertexAttribPointer]

    add rsp, 16

    ; void glEnableVertexAttribArray(GLuint index)
    xor ecx, ecx
    call [rel ptr_glEnableVertexAttribArray]

    jmp loop

.createProgramFail:
    lea rcx, [rel msg_create_program_fail]
    call printf

    mov eax, 1
    jmp exit

loop:
    mov rcx, [rel window_ptr]
    call glfwWindowShouldClose
    test eax, eax
    jnz cleanup

    mov ecx, GL_COLOR_BUFFER_BIT
    call glClear ;paints the window GL_COLOR_BUFFER_BIT, clears the colour buffer with what was selected

    ; void glUseProgram(GLuint program)
    mov rcx, [rel program]
    call [rel ptr_glUseProgram]

    ; bind the VAO every frame
    mov rcx, [rel vao]
    call [rel ptr_glBindVertexArray]

    ; void glDrawArrays(GLenum mode, GLint first, GLsizei count)
    mov ecx, GL_TRIANGLES
    xor edx, edx ; start at vertex index 0
    mov r8d, 3 ; process 3 vertices
    call [rel ptr_glDrawArrays]

    mov rcx, [rel window_ptr]
    call glfwSwapBuffers ;swaps back and front buffers to make the new frame visible

    call glfwPollEvents
    jmp loop

cleanup:
    mov rcx, [rel window_ptr]
    call glfwDestroyWindow

    call glfwTerminate

    xor eax, eax
    jmp exit

create_failed:
    ;debugging
    lea rcx, [rel error_description]
    call glfwGetError ;eax is error code, save in edx

    mov edx, eax
    mov r8, [rel error_description]
    test r8, r8
    jnz .have_description

    lea r8, [rel no_error_msg]

    call glfwTerminate
    mov eax, 1
    jmp exit

.have_description:
    lea rcx, [rel error_format]
    call printf

    call glfwTerminate
    mov eax, 1
    jmp exit

init_failed:
    mov eax, 1

exit:
    add rsp, 40
    ret
