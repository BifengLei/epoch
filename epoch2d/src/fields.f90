MODULE fields

  USE boundary
  USE laser

  IMPLICIT NONE

  REAL(num), DIMENSION(6) :: const
  INTEGER :: large, small, order

CONTAINS

  SUBROUTINE set_field_order(field_order)

    INTEGER, INTENT(IN) :: field_order

    order = field_order

    IF (field_order .EQ. 2) THEN
      const(1:2) = (/ -1.0_num, 1.0_num /)
      large = 1
      small = 0
    ELSE IF (field_order .EQ. 4) THEN
      const(1:4) = (/ 1.0_num/24.0_num, -9.0_num/8.0_num, &
          9.0_num/8.0_num, -1.0_num/24.0_num /)
      large = 2
      small = 1
    ELSE
      const(1:6) = (/ 3.0_num/640.0_num, -25.0_num/384.0_num, &
          75.0_num/64.0_num, -75.0_num/64.0_num, 25.0_num/384.0_num, &
          -3.0_num/640.0_num /)
      large = 3
      small = 2
    ENDIF

  END SUBROUTINE set_field_order



  SUBROUTINE update_e_field

    REAL(num) :: lx, cnx, ly, cny

    lx = dt/dx
    cnx = 0.5_num*lx

    ly = dt/dy
    cny = 0.5_num*ly

    DO iy = 1, ny
      DO ix = 1, nx
        ex(ix, iy) = ex(ix, iy) &
            + cny*c**2 * SUM(const(1:order) * bz(ix, iy-large:iy+small)) &
            - 0.5_num*dt*jx(ix, iy)/epsilon0
      ENDDO
    ENDDO

    DO iy = 1, ny
      DO ix = 1, nx
        ey(ix, iy) = ey(ix, iy) &
            - cnx*c**2 * SUM(const(1:order) * bz(ix-large:ix+small, iy)) &
            - 0.5_num*dt*jy(ix, iy)/epsilon0
      ENDDO
    ENDDO

    DO iy = 1, ny
      DO ix = 1, nx
        ez(ix, iy) = ez(ix, iy) &
            + cnx*c**2 * SUM(const(1:order) * by(ix-large:ix+small, iy)) &
            - cny*c**2 * SUM(const(1:order) * bx(ix, iy-large:iy+small)) &
            - 0.5_num*dt*jz(ix, iy)/epsilon0
      ENDDO
    ENDDO

  END SUBROUTINE update_e_field



  SUBROUTINE update_b_field

    REAL(num) :: lx, cnx, ly, cny

    lx = dt/dx
    cnx = 0.5_num*lx

    ly = dt/dy
    cny = 0.5_num*ly

    DO iy = 1, ny
      DO ix = 1, nx
        bx(ix, iy) = bx(ix, iy) &
            - cny * SUM(const(1:order) * ez(ix, iy-small:iy+large))
      ENDDO
    ENDDO

    DO iy = 1, ny
      DO ix = 1, nx
        by(ix, iy) = by(ix, iy) &
            + cnx * SUM(const(1:order) * ez(ix-small:ix+large, iy))
      ENDDO
    ENDDO

    DO iy = 1, ny
      DO ix = 1, nx
        bz(ix, iy) = bz(ix, iy) &
            - cnx * SUM(const(1:order) * ey(ix-small:ix+large, iy)) &
            + cny * SUM(const(1:order) * ex(ix, iy-small:iy+large))
      ENDDO
    ENDDO

  END SUBROUTINE update_b_field



  SUBROUTINE update_eb_fields_half

    ! Update E field to t+dt/2
    CALL update_e_field

    ! Now have E(t+dt/2), do boundary conditions on E
    CALL efield_bcs

    ! Update B field to t+dt/2 using E(t+dt/2)
    CALL update_b_field

    ! Now have B field at t+dt/2. Do boundary conditions on B
    CALL bfield_bcs(.FALSE.)

    ! Now have E&B fields at t = t+dt/2
    ! Move to particle pusher

  END SUBROUTINE update_eb_fields_half



  SUBROUTINE update_eb_fields_final

    CALL update_b_field

    CALL bfield_bcs(.FALSE.)

    IF (bc_x_min .EQ. c_bc_simple_laser .AND. proc_x_min .EQ. MPI_PROC_NULL) &
        CALL laser_bcs_x_min
    IF (bc_x_min .EQ. c_bc_simple_outflow .AND. proc_x_min .EQ. MPI_PROC_NULL) &
        CALL outflow_bcs_x_min

    IF (bc_x_max .EQ. c_bc_simple_laser .AND. proc_x_max .EQ. MPI_PROC_NULL) &
        CALL laser_bcs_x_max
    IF (bc_x_max .EQ. c_bc_simple_outflow .AND. proc_x_max .EQ. MPI_PROC_NULL) &
        CALL outflow_bcs_x_max

    IF (bc_y_max .EQ. c_bc_simple_laser .AND. proc_y_max .EQ. MPI_PROC_NULL) &
        CALL laser_bcs_y_max
    IF (bc_y_max .EQ. c_bc_simple_outflow .AND. proc_y_max .EQ. MPI_PROC_NULL) &
        CALL outflow_bcs_y_max

    IF (bc_y_min .EQ. c_bc_simple_laser .AND. proc_y_min .EQ. MPI_PROC_NULL) &
        CALL laser_bcs_y_min
    IF (bc_y_min .EQ. c_bc_simple_outflow .AND. proc_y_min .EQ. MPI_PROC_NULL) &
        CALL outflow_bcs_y_min

    CALL bfield_bcs(.TRUE.)

    CALL update_e_field

    CALL efield_bcs

  END SUBROUTINE update_eb_fields_final

END MODULE fields
