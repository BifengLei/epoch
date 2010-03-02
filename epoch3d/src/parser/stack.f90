MODULE stack

  USE shared_data

  IMPLICIT NONE

  TYPE :: float_stack
    REAL(num), DIMENSION(1000) :: stack
    INTEGER :: stack_point
  END TYPE float_stack

  TYPE(float_stack) :: eval_stack

CONTAINS

  SUBROUTINE push_on_eval(value)

    REAL(num), INTENT(IN) :: value
    eval_stack%stack_point = eval_stack%stack_point+1
    eval_stack%stack(eval_stack%stack_point) = value

  END SUBROUTINE push_on_eval



  FUNCTION pop_off_eval()

    REAL(num) :: pop_off_eval

    pop_off_eval = eval_stack%stack(eval_stack%stack_point)
    eval_stack%stack_point = eval_stack%stack_point-1

  END FUNCTION pop_off_eval



  SUBROUTINE get_values(count, values)

    INTEGER, INTENT(IN) :: count
    REAL(num), DIMENSION(1:) :: values

    INTEGER :: i

    DO i = 1, count
      values(count-i+1) = pop_off_eval()
    ENDDO

  END SUBROUTINE get_values

END MODULE stack