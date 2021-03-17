require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @document = documents(:one)
  end

  test "should get index" do
    get documents_url
    assert_response :success
  end

  test "should get new" do
    sign_in users(:one)
    get new_document_url
    assert_response :success
  end

  test "should create document" do
    sign_in users(:one)

    assert_difference('Document.count') do
      post documents_url, params: {
        document: {
          title: "Three",
          user_id: documents(:one).user_id
        }
      }
    end

    assert_redirected_to document_url(Document.first)
  end

  test "should show document" do
    get document_url(documents(:one))
    assert_response :success
  end

  test "should get edit" do
    sign_in documents(:one).user
    get edit_document_url(documents(:one))
    assert_response :success
  end

  test "should update document" do
    sign_in documents(:one).user
    patch document_url(documents(:one)), params: {
      document: {
        title: "New Title"
      }
    }
    assert_redirected_to document_url(documents(:one))
  end

  test "should destroy document" do
    sign_in documents(:one).user
    assert_difference('Document.count', -1) do
      delete document_url(documents(:one))
    end

    assert_redirected_to documents_url
  end
end
