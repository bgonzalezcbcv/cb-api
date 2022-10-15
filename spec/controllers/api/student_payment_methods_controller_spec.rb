require 'rails_helper'

RSpec.describe Api::StudentPaymentMethodsController do

  describe 'POST create' do
    let(:user) { FactoryBot.create(:user) }
    let(:student) { FactoryBot.create(:student) }
    let(:payment_method) { FactoryBot.create(:payment_method, method: Faker::Music::Prince.album) }

    let(:student_payment_method) { FactoryBot.build(:student_payment_method, student_id: student.id, payment_method_id: payment_method.id) }
    let(:student_payment_method_attrs){ student_payment_method.attributes }

    context 'when user is signed in' do
      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        post :create, params: params

        response
      end

      context 'with valid data' do
        let(:params) { {student_payment_method: student_payment_method_attrs, format: :json} }

        its(:status) { should eq(201) }

        its(:body) do
          should include_json(student_payment_method: {
            student_id: student_payment_method.student_id,
            payment_method_id: student_payment_method.payment_method_id,
            year: student_payment_method.year.to_s
          })
        end
      end

      context 'with invalid data' do
        let(:params) { {student_payment_method: {student_id: student.id, payment_method_id: payment_method.id, year: nil}, format: :json} }

        its(:status) { should eq(422) }

        its(:body) do
          should include_json(error: {
            key: 'record_invalid',
            description: {
              year: ['no puede estar en blanco']
            }
          })
        end
      end

      context 'with invalid student id' do
        let(:invalid_student_payment_method_attrs) { {student_id: -1, payment_method_id: payment_method.id, year: student_payment_method.year} }

        let(:params) { {student_payment_method: invalid_student_payment_method_attrs, format: :json} }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'student.not_found',
            description: I18n.t('student.not_found')
          })
        end
      end

      context 'with invalid payment_method id' do
        let(:invalid_student_payment_method_attrs) { {student_id: student.id, payment_method_id: -1, year: student_payment_method.year} }

        let(:params) { {student_payment_method: invalid_student_payment_method_attrs, format: :json} }

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'payment_method.not_found',
            description: I18n.t('payment_method.not_found')
          })
        end
      end
    end

    context 'when user is not signed in' do
      let(:params) { {student_payment_method: student_payment_method_attrs, format: :json} }

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
    context 'when user is signed in' do
      let(:user) { FactoryBot.create(:user) }
      let(:student) { FactoryBot.create(:student) }
      let(:payment_method) { FactoryBot.create(:payment_method, method: Faker::Music::Prince.album) }
  
      let(:student_payment_method) { FactoryBot.create(:student_payment_method, student_id: student.id, payment_method_id: payment_method.id) }

      subject do
        request.headers['Authorization'] = "Bearer #{generate_token(user)}"
        patch :update, params: params

        response
      end

      context 'with valid data' do
       let(:params) do
          { student_payment_method:{year: Date.yesterday,
            student_id: student_payment_method.student_id,
            payment_method_id: student_payment_method.payment_method_id },
            id: student_payment_method.id,
            format: :json }
        end

        it 'changes the year' do
          expect {
            subject

            student_payment_method.reload
          }.to change(student_payment_method, :year).to(Date.yesterday)
        end

        its(:status) { should eq(200) }

        its(:body) do
          should include_json(student_payment_method: {
            id: student_payment_method.id,
            student_id: student_payment_method.student_id,
            payment_method_id: student_payment_method.payment_method_id,
            year: Date.yesterday.to_s
          })
        end

      end

      context 'with invalid id' do
        let(:params) do
          { student_payment_method: {year: Date.yesterday,
            student_id: student_payment_method.student_id,
            payment_method_id: student_payment_method.payment_method_id}, id: -1,
            format: :json }
        end

        its(:status) { should eq(404) }

        its(:body) do
          should include_json(error: {
            key: 'student_payment_method.not_found',
            description: I18n.t('student_payment_method.not_found')
          })
        end
      end

      context 'with invalid data' do
        let(:params) do { student_payment_method: {year: '',
          student_id: student_payment_method.student_id,
          payment_method_id: student_payment_method.payment_method_id}, id: student_payment_method.id,
          format: :json } 
      end

      its(:status) { should eq(422) }

      its(:body) do
        should include_json(error: {
          key: 'record_invalid',
          description: {
            year: ['no puede estar en blanco']
          }
        })
      end
    end
    end
    context 'when user is not signed in' do
      let(:student) { FactoryBot.create(:student) }
      let(:payment_method) { FactoryBot.create(:payment_method, method: Faker::Music::Prince.album) }
  
      let(:student_payment_method) { FactoryBot.create(:student_payment_method, student_id: student.id, payment_method_id: payment_method.id) }

      let(:params) do
        { student_payment_method:{year: '01-01-1900',
          student_id: student_payment_method.student_id,
          payment_method_id: student_payment_method.payment_method_id },
          id: student_payment_method.id,
          format: :json }
      end

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
end
