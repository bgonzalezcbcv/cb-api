
require 'rails_helper'

RSpec.describe Api::GroupsController do

  describe 'GET index' do
    let(:user) { FactoryBot.create(:user) }
    let(:params) { { format: :json } }
    let(:group) { FactoryBot.create(:group) }
    let(:grade) { group.grade }

    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :index, params: params

        response
      end

      context 'with groups' do
        before do
          group
        end

        context 'with teachers, principal and support teacher' do
          let(:principal) { FactoryBot.create(:user, :principal) }
          let(:teacher) { FactoryBot.create(:user) }
          let(:support_teacher) { FactoryBot.create(:user, :support_teacher) }

          before do
            UserGroup.create(group: group, user: principal, role_id: Role.find_by(name: :principal).id)
            UserGroup.create(group: group, user: teacher, role_id: Role.find_by(name: :teacher).id)
            UserGroup.create(group: group, user: support_teacher, role_id: Role.find_by(name: :support_teacher).id)
          end

          its(:status) { should eq(200) }

          its(:body) do
            should include_json(groups: [{
              id: group.id,
              name: group.name,
              grade: {
                id: grade.id,
                name: grade.name
              },
              principals: [{
                ci: principal.ci.to_s,
                name: principal.name,
                surname: principal.surname,
                birthdate: principal.birthdate.to_s,
                address: principal.address,
                email: principal.email
              }],
              support_teachers: [{
                ci: support_teacher.ci.to_s,
                name: support_teacher.name,
                surname: support_teacher.surname,
                birthdate: support_teacher.birthdate.to_s,
                address: support_teacher.address,
                email: support_teacher.email
              }],
              teachers: [{
                ci: teacher.ci.to_s,
                name: teacher.name,
                surname: teacher.surname,
                birthdate: teacher.birthdate.to_s,
                address: teacher.address,
                email: teacher.email
              }]
            }])
          end
        end
      end

      context 'without groups' do
        its(:status) { should eq(200) }

        its(:body) do
          should include_json(groups: [])
        end
      end

    end

    context 'when user is not signed in' do
      subject do
        get :index, params: params

        response
      end

      its(:status) { should eq(403) }

      its(:body) do
        should include_json(error: {
          key: 'forbidden.required_signed_in',
          description: I18n.t('errors.forbidden.required_signed_in')
        })
      end
    end
  end

  describe 'POST create' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:grade) { FactoryBot.create(:grade) }
      let(:group_attrs) { FactoryBot.attributes_for(:group) }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create, params: params

        response
      end

      context 'with valid data' do
        context 'with valid grade id' do
          let(:params) { {grade_id: grade.id, group: group_attrs, format: :json} }

          its(:status) { should eq(201) }

          its(:body) do
            should include_json(grade: {
              group: {
                name: group_attrs[:name],
                year: group_attrs[:year],
                grade_name: grade.name
              }
            })
          end
        end
      end

      context 'with invalid data' do
        context 'with invalid data' do
          let(:invalid_group_attrs) { FactoryBot.attributes_for(:group, name: '') }

          let(:params) { {grade_id: grade.id, group: invalid_group_attrs, format: :json} }

          its(:status) { should eq(422) }

          its(:body) do
            should include_json(error: {
              key: 'record_invalid',
              description: {
                name: ['no puede estar en blanco']
              }
            })
          end
        end

        context 'with invalid grade id' do
          let(:params) { {grade_id: -1, group: group_attrs, format: :json} }

          its(:status) { should eq(404) }

          its(:body) do
            should include_json(error: {
              key: 'grade.not_found',
              description: I18n.t('grade.not_found')
            })
          end
        end

        context 'with duplicate index' do
          let(:second_group) do
            FactoryBot.create(:group)
          end
          let(:second_group_attrs) { second_group.attributes }

          let(:params) { {grade_id: second_group.grade.id, group: second_group_attrs, format: :json} }

          its(:status) { should eq(422) }

          its(:body) do
            should include_json(error: {
              key: 'record_invalid',
              description: {
                name: ['ya está en uso']
              }
            })
          end
        end

      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:grade) { FactoryBot.create(:grade) }
      let(:group_attrs) { FactoryBot.attributes_for(:group) }
      let(:params) { {grade_id: grade.id, group: group_attrs, format: :json} }

      subject do
        post :create, params: params

        response
      end

      its(:status) { should eq(403) }

      its(:body) do
        should include_json(error: {
          key: 'forbidden.required_signed_in',
          description: I18n.t('errors.forbidden.required_signed_in')
        })
      end
    end
  end

  describe 'PATCH update' do
    let(:user) { FactoryBot.create(:user) }
    let(:group) { FactoryBot.create(:group) }
    let(:grade) { group.grade }

    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update, params: params

        response
      end

      context 'with valid data' do
        let(:group_attrs) { FactoryBot.attributes_for(:group) }
        let(:params) { {grade_id: grade.id, id: group.id, group: group_attrs, format: :json} }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(grade: {
            group: {
              name: group_attrs[:name],
              year: group_attrs[:year]
            }
          })
        end
      end

      context 'with invalid grade id' do
        let(:group_attrs) { FactoryBot.attributes_for(:group) }
        let(:params) { {grade_id: -1, id: group.id, group: group_attrs, format: :json} }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'grade.not_found',
            description: I18n.t('grade.not_found')
          })
        end
      end

      context 'with invalid group id' do
        let(:group_attrs) { FactoryBot.attributes_for(:group) }
        let(:params) { {grade_id: grade.id, id: -1, group: group_attrs, format: :json} }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'group.not_found',
            description: I18n.t('group.not_found')
          })
        end
      end

      context 'with invalid data duplicate index' do
        let(:second_group) do
          FactoryBot.create(:group, grade_id: grade.id)
        end
        let(:second_group_attrs) { second_group.attributes }

        let(:params) { {grade_id: grade.id, id: group.id, group: second_group_attrs, format: :json} }

        its(:status) { should eq(422) }

        its(:body) do
          should include_json(error: {
            key: 'record_invalid',
            description: {
              name: ['ya está en uso']
            }
          })
        end
      end

    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:group) { FactoryBot.create(:group) }
      let(:grade) { group.grade }
      let(:group_attrs) { FactoryBot.attributes_for(:group) }

      let(:params) { {grade_id: grade.id, id: group.id, group: group_attrs, format: :json} }

      subject do
        patch :update, params: params

        response
      end

      its(:status) { should eq(403) }

      its(:body) do
        should include_json(error: {
          key: 'forbidden.required_signed_in',
          description: I18n.t('errors.forbidden.required_signed_in')
        })
      end
    end
  end

  describe 'GET teachers' do
    let(:user) { FactoryBot.create(:user, :with_group) }
    let(:group) { user.groups.first }
    let(:grade) { group.grade }

    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :teachers, params: params

        response
      end

      context 'with teachers in specific group' do
        let(:params) { { group_id: group.id, format: :json } }
        its(:status) { should eq(200) }

        its(:body) do
          should include_json(teachers: [{
            ci: user.ci,
            name: user.name,
            surname: user.surname,
            groups: [{
              name: user.groups.first.name,
              year: user.groups.first.year,
              grade: {
                id: grade.id,
                name: grade.name
              },
              teachers: [{
                ci: user.ci.to_s,
                name: user.name,
                surname: user.surname,
                birthdate: user.birthdate.to_s,
                address: user.address,
                email: user.email
              }],
              principals: [],
              support_teachers: []
            }]
          }])
        end
      end

      context 'without teachers in specific group' do
        let(:params) { { group_id: group.id, format: :json } }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(teachers: [])
        end
      end
    end

    context 'when user is not signed in' do
      let(:group) { FactoryBot.create(:group) }

      let(:params) { { group_id: group.id, format: :json} }

      subject do
        get :teachers, params: params

        response
      end

      its(:status) { should eq(403) }

      its(:body) do
        should include_json(error: {
          key: 'forbidden.required_signed_in',
          description: I18n.t('errors.forbidden.required_signed_in')
        })
      end
    end
  end

  describe 'GET students' do
    let(:user) { FactoryBot.create(:user) }
    let(:student) { FactoryBot.create(:student, :with_group) }
    let(:group) { student.group }

    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :students, params: params

        response
      end

      context 'with group existing' do
        let(:params) { { group_id: group.id, format: :json } }

        context 'with students' do
          its(:status) { should eq(200) }

          its(:body) do
            should include_json(students: [
              ci: student.ci,
              name: student.name,
              surname: student.surname,
              birthplace: student.birthplace.to_s,
              birthdate: student.birthdate.to_s,
              nationality: student.nationality,
              schedule_start: student.schedule_start,
              schedule_end: student.schedule_end,
              tuition: student.tuition,
              reference_number: student.reference_number,
              office: student.office,
              status: student.status,
              first_language: student.first_language,
              address: student.address,
              neighborhood: student.neighborhood,
              medical_assurance: student.medical_assurance,
              emergency: student.emergency,
              vaccine_expiration: student.vaccine_expiration.to_s,
              vaccine_name: student.vaccine_name,
              phone_number: student.phone_number,
              inscription_date: student.inscription_date.to_s,
              starting_date: student.starting_date.to_s,
              contact: student.contact,
              contact_phone: student.contact_phone,
              group: {
                id: group.id,
                name: group.name,
                year: group.year,
                grade_name: group.grade_name
              }
            ])
          end
        end

        context 'without students' do
          its(:status) { should eq(200) }

          its(:body) do
            should include_json(students: [])
          end
        end
      end

      context 'with group not existing' do
        let(:params) { { group_id: -1, format: :json } }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json( error: {
            key: "group.not_found",
            description: I18n.t('group.not_found')
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:params) { { group_id: -1, format: :json } }

      subject do
        get :students, params: params

        response
      end

      its(:status) { should eq(403) }

      its(:body) do
        should include_json(error: {
          key: 'forbidden.required_signed_in',
          description: I18n.t('errors.forbidden.required_signed_in')
        })
      end
    end
  end
end
