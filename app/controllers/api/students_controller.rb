class Api::StudentsController < Api::BaseController
  def create
    student = Student.create!(student_params)

    render json: StudentSerializer.new.serialize_to_json(student), status: :created
  end

  def show
    student = Student.find(params[:id])
    render json: StudentSerializer.find.serialize_to_json(student), status: :ok
  end  

  private

  def student_params
    params.require(:student).permit(:ci, :surname,
      :name, :birthplace, :birthdate, :nationality, :schedule_start, :schedule_end, :tuition,
      :reference_number, :office, :status,
      :first_language, :address, :neighborhood, :medical_assurance,
      :emergency, :vaccine_name, :vaccine_expiration, :phone_number,
      :inscription_date, :starting_date, :contact, :contact_phone
    )
  end
end