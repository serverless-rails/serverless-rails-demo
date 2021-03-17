json.extract! document, :id, :title, :body, :created_at, :updated_at
json.url document_url(document, format: :json)
json.body document.body.to_s
json.last_updated_string time_ago_in_words(document.updated_at)
