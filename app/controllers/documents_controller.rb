class DocumentsController < ApplicationController
  before_action :authenticate_user!, only: %i[ new create edit update destroy ]
  before_action :set_document, only: %i[ show edit update destroy ]
  before_action :require_owner, only: %i[ edit update destroy ]

  def index
    @documents = Document.all
  end

  def show
  end

  def new
    @document = Document.new
  end

  def edit
  end

  def create
    @document = current_user.documents.new(document_params)

    respond_to do |format|
      if @document.save
        new_row = render_to_string(partial: 'documents/document_row', object: @document)
        DocumentChannel.broadcast_to "updates", {
          id: @document.id,
          user_id: @document.user_id,
          action: "created",
          html: new_row
        }
        format.html { redirect_to @document, notice: "Document was successfully created." }
        format.json { render :show, status: :created, location: @document }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @document.update(document_params)
        new_row = render_to_string(partial: "documents/document_row", object: @document)
        json = render_to_string(partial: "documents/document", formats: "json", object: @document)
        DocumentChannel.broadcast_to "updates", {
          id: @document.id,
          action: "updated",
          html: new_row,
          json: JSON.parse(json)
        }

        format.html { redirect_to @document, notice: "Document was successfully updated." }
        format.json { render :show, status: :ok, location: @document }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @document.destroy
    DocumentChannel.broadcast_to("updates", { id: @document.id, action: 'deleted' })
    respond_to do |format|
      format.html { redirect_to documents_url, notice: "Document was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    def set_document
      @document = Document.friendly.find(params[:id])
    end

    def require_owner
      if @document.user != current_user
        render status: 403
        return
      end
    end

    def document_params
      params.require(:document).permit(:title, :body)
    end
end
