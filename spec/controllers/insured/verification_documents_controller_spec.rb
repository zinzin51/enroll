require 'rails_helper'

RSpec.describe Insured::VerificationDocumentsController, :type => :controller do
  let(:user) { double("User", person: person, :has_hbx_staff_role? => true) }
  let(:person){ FactoryGirl.create(:person) }
  let(:family)  {FactoryGirl.create(:family, :with_primary_family_member, :person => person)}
  let(:permission) { FactoryGirl.create(:permission, :hbx_staff) }
  let(:hbx_staff_role) { FactoryGirl.create(:hbx_staff_role, person: person, subrole: "hbx_staff", permission_id: permission.id)}
  let(:family_member) {double(person: person, family: family)}
  let(:consumer_role) { {consumer_role: ''} }

  context '#Upload' do

    describe 'tests file Uploading functionality' do
      let(:file) { double }
      let(:temp_file) { double }
      let(:consumer_role_params) {}
      let(:params) { {person: {consumer_role: ''}, file: [file]} }
      let(:bucket_name) { 'id-verification' }
      let(:doc_id) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{bucket_name}{#sample-key" }
      let(:file_path) { File.dirname(__FILE__) } # a sample file path
      let(:cleaned_params) { {"0" => {"subject" => "I-327 (Reentry Permit)", "id" => "55e7fef5536167bb822e0000", "alien_number" => "999999999"}} }

      before(:each) do
        allow(file).to receive(:original_filename).and_return('some-filename')
        allow(file).to receive(:tempfile).and_return(temp_file)
        allow(temp_file).to receive(:path)
        allow(user).to receive(:person).and_return(person)
        allow(person).to receive(:hbx_staff_role).and_return(hbx_staff_role)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:person_consumer_role)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_path).and_return(file_path)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:file_name).and_return('sample-filename')
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        controller.instance_variable_set(:@person, person)
        sign_in user
        family.family_members.first.person = person
        family.save
        family_member = person.primary_family.family_members.last
        params[:family_member] = family_member
      end

      it 'should successfully call upload method and do a redirect' do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with('sample-filename', doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        post :upload, params

        expect(response.code).to eq('302')
      end

      it 'successfully uploads a file' do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with('sample-filename', doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        post :upload, params

        expect(flash[:notice]).to eq('File Saved')
      end

      it 'errors out if doc_uri is not present' do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with('sample-filename', doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(false)
        post :upload, params

        expect(flash[:error]).to eq('Could not save file')
      end

      it 'errors out if update_vlp_documents fails' do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with('sample-filename', doc_id).and_return(false)
        request.env['HTTP_REFERER'] = 'http://foo.com'
        post :upload, params

        expect(flash[:error]).to eq('Could not save file. ')

        expect(response).to redirect_to 'http://foo.com'
      end

      it 'errors out if file key param is not present' do
        params[:file] = nil
        post :upload, params

        expect(flash[:error]).to eq('File not uploaded. Please select the file to upload.')
      end

      it 'should redirect to verification_insured_families_path if file uploaded or failed' do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:update_vlp_documents).with('sample-filename', doc_id).and_return(true)
        allow(Aws::S3Storage).to receive(:save).with(file_path, bucket_name).and_return(doc_id)
        post :upload, params

        expect(response).to redirect_to 'http://test.host/insured/families/verification'
      end
    end

    context "Failed Download" do
      it "fails with an error message" do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).and_return(nil)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
        sign_in user
        get :download, key:"sample-key"
        expect(flash[:error]).to eq("File does not exist or you are not authorized to access it.")
      end
    end

    context "Successful Download" do
      it "downloads a file" do
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:vlp_docs_clean).and_return(true)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_family)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:get_document).with('sample-key').and_return(VlpDocument.new)
        allow_any_instance_of(Insured::VerificationDocumentsController).to receive(:send_data).with(nil, {:content_type=>"application/octet-stream", :filename=>"untitled"}) {
          @controller.render nothing: true # to prevent a 'missing template' error
        }
        sign_in user
        get :download, key:"sample-key"
        expect(flash[:error]).to be_nil
        expect(response.status).to eq(200)
      end
    end

  end
end