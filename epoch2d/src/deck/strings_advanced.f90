MODULE strings_advanced


  USE shunt
  USE evaluator

  IMPLICIT NONE

CONTAINS

  SUBROUTINE get_filename(str_in, str_out, got_file, err)

    CHARACTER(*), INTENT(IN) :: str_in
    CHARACTER(*), INTENT(OUT) :: str_out
    LOGICAL, INTENT(OUT) :: got_file
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: str_len, char, pos, delimiter, c

    str_len = LEN(str_in)
    pos = -1
    got_file = .FALSE.

    c = ICHAR(str_in(1:1))
    ! ACHAR(39) = '\'', ACHAR(34) = '"'
    IF (c .NE. 39 .AND. c .NE. 34) RETURN

    delimiter = c

    DO char = 2, str_len
      c = ICHAR(str_in(char:char))
      IF (c .EQ. delimiter) THEN
        pos = char
        EXIT
      ENDIF
    ENDDO

    IF (pos .LT. 0) THEN
      err = IOR(err, c_err_bad_value)
      RETURN
    ENDIF

    got_file = .TRUE.
    str_out = str_in(2:pos-1)

  END SUBROUTINE get_filename



  SUBROUTINE split_off_int(str_in, str_out, int_out, err)

    CHARACTER(*), INTENT(IN) :: str_in
    CHARACTER(*), INTENT(OUT) :: str_out
    INTEGER, INTENT(OUT) :: int_out
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: str_len, char, pos, c

    str_len = LEN(str_in)
    pos = -1

    DO char = 1, str_len
      c = ICHAR(str_in(char:char))
      ! ACHAR(48)-ACHAR(57) = '0'-'9'
      IF (c .GT. 47 .AND. c .LT. 58) THEN
        pos = char
        EXIT
      ENDIF
    ENDDO

    IF (pos .LT. 0) THEN
      err = IOR(err, c_err_bad_value)
      RETURN
    ENDIF

    str_out = str_in(1:pos-1)
    int_out = as_integer_simple(str_in(pos:str_len), err)

  END SUBROUTINE split_off_int



  SUBROUTINE split_range(str_in, real1, real2, err)

    CHARACTER(*), INTENT(IN) :: str_in
    REAL(num), INTENT(OUT) :: real1, real2
    INTEGER, INTENT(INOUT) :: err
    TYPE(primitive_stack) :: output
    REAL(num), DIMENSION(2) :: array

    CALL initialise_stack(output)
    CALL tokenize(str_in, output, err)
    IF (err .EQ. c_err_none) &
        CALL evaluate_at_point_to_array(output, 0, 0, 2, array, err)
    real1 = array(1)
    real2 = array(2)
    CALL deallocate_stack(output)

  END SUBROUTINE split_range



  SUBROUTINE get_vector(str_in, array, err)

    CHARACTER(*), INTENT(IN) :: str_in
    REAL(num), DIMENSION(:), INTENT(OUT) :: array
    INTEGER, INTENT(INOUT) :: err
    TYPE(primitive_stack) :: output
    INTEGER :: ndim

    ndim = SIZE(array)
    CALL initialise_stack(output)
    CALL tokenize(str_in, output, err)
    IF (err .EQ. c_err_none) &
        CALL evaluate_at_point_to_array(output, 0, 0, ndim, array, err)
    CALL deallocate_stack(output)

  END SUBROUTINE get_vector



  FUNCTION as_integer(str_in, err)

    CHARACTER(*), INTENT(IN) :: str_in
    INTEGER, INTENT(INOUT) :: err
    INTEGER :: as_integer
    as_integer = NINT(as_real(str_in, err))

  END FUNCTION as_integer



  FUNCTION as_long_integer(str_in, err)

    CHARACTER(*), INTENT(IN) :: str_in
    INTEGER, INTENT(INOUT) :: err
    INTEGER(KIND=8) :: as_long_integer
    as_long_integer = NINT(as_real(str_in, err),8)

  END FUNCTION as_long_integer



  FUNCTION as_real(str_in, err)

    CHARACTER(*), INTENT(IN) :: str_in
    INTEGER, INTENT(INOUT) :: err
    REAL(num) :: as_real
    TYPE(primitive_stack) :: output

    CALL initialise_stack(output)
    CALL tokenize(str_in, output, err)
    as_real = evaluate(output, err)
    CALL deallocate_stack(output)

  END FUNCTION as_real



  SUBROUTINE as_list(str_in, array, n_elements, err)

    CHARACTER(*), INTENT(IN) :: str_in
    INTEGER, INTENT(OUT) :: array(:)
    INTEGER, INTENT(OUT) :: n_elements
    INTEGER, INTENT(INOUT) :: err
    TYPE(primitive_stack) :: output

    CALL initialise_stack(output)
    CALL tokenize(str_in, output, err)
    IF (err .EQ. c_err_none) &
        CALL evaluate_as_list(output, array, n_elements, err)
    CALL deallocate_stack(output)

  END SUBROUTINE as_list



  SUBROUTINE evaluate_string_in_space(str_in, data_out, x1, x2, y1, y2, err)

    CHARACTER(*), INTENT(IN) :: str_in
    INTEGER, INTENT(INOUT) :: err
    INTEGER, INTENT(IN) :: x1, x2, y1, y2
    REAL(num), DIMENSION(:,:), INTENT(OUT) :: data_out
    TYPE(primitive_stack) :: output
    INTEGER :: ix, iy

    CALL initialise_stack(output)
    CALL tokenize(str_in, output, err)

    DO iy = y1, y2
      DO ix = x1, x2
        data_out(ix-x1+1, iy-y1+1) = evaluate_at_point(output, ix, iy, err)
      ENDDO
    ENDDO
    CALL deallocate_stack(output)

  END SUBROUTINE evaluate_string_in_space

END MODULE strings_advanced
