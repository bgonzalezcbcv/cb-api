require 'rails_helper'

RSpec.describe Api::MeController do
  describe 'GET show' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_document, :with_complementary_information, :with_absence) }
      let(:complementary_information) { user.complementary_informations.first }
      let(:document) { user.documents.first }
      let(:absence) { user.absences.first }

      let(:params) { { id: user.id, format: :json } }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :show, params: params

        response
      end

      context 'with valid data' do

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(me: {
            ci: user.ci.to_s,
            name: user.name,
            surname: user.surname,
            birthdate: user.birthdate.to_s,
            address: user.address,
            email: user.email,
            absences: [{
              start_date: absence.start_date.to_s,
              end_date: absence.end_date.to_s,
              reason: absence.reason
            }],
            complementary_informations: [{
              date: complementary_information.date.to_s,
              description: complementary_information.description
             }],
            documents:[{
              document_type: document.document_type,
              upload_date: document.upload_date.to_s,
            }]
        })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { id: user.id, format: :json } }

      subject do
        get :show, params: params

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
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update, params: params

        response
      end

      context 'with valid data' do
        let(:params) { {user: {address: 'New address 1234'}, format: :json} }

        it 'changes the address' do
          expect {
            subject

            user.reload
          }.to change(user, :address).to('New address 1234')
        end

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(user: {
            ci: user[:ci].to_s,
            name: user[:name],
            surname: user[:surname],
            birthdate: user[:birthdate].to_s,
            address: 'New address 1234',
            email: user[:email]
          })
        end
      end

      context 'with invalid data' do
        let(:params) { {user: {ci: '111'}, format: :json} }

        its(:status) { should eq(422) }

        its(:body) do
          should include_json(error: {
            key: 'record_invalid',
            description: {
              ci: ['es demasiado corto (8 caracteres mínimo)']
            }
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { id: user.id, format: :json} }

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

  describe 'PATCH update password' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :password, params: params

        response
      end

      context 'with valid data' do
        let(:params) { {user: { password:'new_password1', password_confirmation:'new_password1' }, format: :json} }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(user: {
            ci: user[:ci].to_s,
            name: user[:name],
            surname: user[:surname],
            birthdate: user[:birthdate].to_s,
            address: user[:address],
            email: user[:email]
          })
        end
      end

      context 'with invalid data' do
        let(:params) { {user: { password: '111', password_confirmation: '111' }, format: :json} }

        its(:status) { should eq(422) }

        its(:body) do
          should include_json(error: {
            key: 'record_invalid',
            description: {
              password: ['es demasiado corto (6 caracteres mínimo)']
            }
          })
        end
      end

      context 'with invalid password_confirmation' do
        let(:params) { {user: { password:'new_password', password_confirmation:'diferent_password' }, format: :json} }

        its(:status) { should eq(422) }

        its(:body) do
          should include_json(error: {
            key: 'record_invalid',
            description: {
              password_confirmation: ['no coincide']
            }
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { user: { password:'new_password', password_confirmation:'new_password' }, format: :json} }

      subject do
        patch :password, params: params

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

  describe 'POST create_document' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_document) }
      let(:document) { user.documents.first }
      let(:document_attrs) { document.attributes }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create_document, params: params

        response
      end

      context 'with valid data' do
        let(:params) { document_attrs.merge({format: :json}) }

        its(:status) { should eq(201) }

        its(:body) do
          should include_json(document: {
            document_type: document.document_type,
            upload_date: document.upload_date.to_s,
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user, :with_document) }
      let(:document) { user.documents.first }
      let(:document_attrs) { document.attributes }
      let(:params) { document_attrs.merge({format: :json}) }

      subject do
        post :create_document, params: params

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

  describe 'POST create_complementary_information' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_complementary_information) }
      let(:complementary_information) { user.complementary_informations.first }
      let(:complementary_information_attrs) { complementary_information.attributes }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create_complementary_information, params: params

        response
      end

      context 'with valid data' do
        let(:params) { complementary_information_attrs.merge({format: :json}) }

        its(:status) { should eq(201) }

        its(:body) do
          should include_json(complementary_information: {
            date: complementary_information.date.to_s,
            description: complementary_information.description
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user, :with_complementary_information) }
      let(:complementary_information) { user.complementary_informations.first }
      let(:complementary_information_attrs) { complementary_information.attributes }

      let(:params) { complementary_information_attrs.merge({format: :json}) }
      subject do
        post :create_complementary_information, params: params

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

  describe 'POST create_absences' do
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:absence_attrs) { FactoryBot.attributes_for(:absence) }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create_absence, params: params

        response
      end

      context 'with valid data' do
        let(:params) { absence_attrs.merge({user_id: user.id, format: :json}) }

        its(:status) { should eq(201) }

        its(:body) do
          should include_json(absence: {
            start_date: absence_attrs[:start_date].to_s,
            end_date: absence_attrs[:end_date].to_s,
            reason: absence_attrs[:reason]
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:absence_attrs) { FactoryBot.attributes_for(:absence) }
      let(:params) { absence_attrs.merge({user_id: user.id, format: :json}) }

      subject do
        post :create_absence, params: params

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
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_group_and_students) }
      let(:group) { user.groups.first }
      let(:student) { group.students.first }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :students, params: params

        response
      end

      context 'with valid data' do
        let(:params) { { group_id: group.id, format: :json } }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(group: {
            id: group.id,
            name: group.name,
            year: group.year,
            grade_name: group.grade_name,
            students: [{
              ci: student.ci
            }]
          })
        end
      end

      context 'with invalid data' do
        let(:params) { {group_id: -1, format: :json} }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'group.not_found',
            description: I18n.t('group.not_found')
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { id: user.id, format: :json } }

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

  describe 'GET groups' do
    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :groups, params: params

        response
      end

      context 'with groups' do
        let(:user) { FactoryBot.create(:user, :with_group) }
        let(:group) { user.groups.first }
        let(:grade) { group.grade }

        let(:params) { { format: :json } }

        its(:status) { should eq(200) }

        its(:body) do
            should include_json(groups: [{
              id: group.id,
              name: group.name,
              grade: {
                id: grade.id,
                name: grade.name
              },
              principals: [],
              support_teachers: [],
              teachers: []
            }])
          end
      end

      context 'without groups' do
        let(:user) { FactoryBot.create(:user) }
        let(:params) { { format: :json } }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(groups: [])
        end
      end
    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { id: user.id, format: :json } }

      subject do
        get :groups, params: params

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
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user, :with_group_and_students) }
      let(:group) { user.groups.first }
      let(:grade) { group.grade }
      let(:student) { group.students.first }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        get :teachers, params: params

        response
      end

      context 'with teachers' do
        let(:params) { { format: :json } }

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(teachers: [{
            name: user.name,
            surname: user.surname,
            groups: [{
              name: group.name,
              year: group.year,
              grade: {
                id: grade.id,
                name: grade.name
              }
            }]
          }])
        end
      end

    end

    context 'when user is not signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:params) { { id: user.id, format: :json } }

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
