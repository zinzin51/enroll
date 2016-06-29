subject = '1095A' # the business-type of documents being uploaded

dir = ARGV[0]

def hbx_id(file_name)
  file_name.split("_")[3]
end

def version_type(file_name)
  if file_name.downcase.include? "corrected"
   'corrected'
  elsif file_name.downcase.include? "void"
   'void'
  else
   'new'
  end
end

Dir.glob("#{dir}/**/*").each do |file|
  next if File.directory? file

  begin
    key = Aws::S3Storage.save(file, 'tax-documents')

    person = Person.where(hbx_id: hbx_id(File.basename(file))).first

    if person.nil?
      puts "Could not find person for doc #{File.basename(file)}"
      next
    end

    family = person.primary_family
  
    if family.nil?
      puts "Could not find primary_family for doc #{File.basename(file)}"
      next
    end

    content_type = MIME::Types.type_for(File.basename(file)).first.content_type

    family.documents << TaxDocument.new({identifier: "urn:openhbx:terms:v1:file_storage:s3:bucket:tax_documents##{key}",
                                         title: File.basename(file), format: content_type, subject: subject,
                                         rights: 'pii_restricted', version_type: version_type(file)})
    family.save!
  rescue => e
    puts "Error #{file} #{e.message}"
  end
end