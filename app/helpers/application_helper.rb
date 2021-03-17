module ApplicationHelper
  def bootstrap_class_for(flash_type)
    {
      success: "alert-success",
      error: "alert-danger",
      alert: "alert-warning",
      notice: "alert-info"
    }.stringify_keys[flash_type.to_s] || flash_type.to_s
  end

  def avatar_path(object, options = {})
    size = options[:size] || 180
    if object.respond_to?(:avatar) && object.avatar.attached? && object.avatar.variable?
      object.avatar.variant(resize_to_fill: [size, size, { gravity: 'Center' }])
    else
      "https://secure.gravatar.com/avatar/00000000000000000000000000000000?s=#{size}&d=mp"
    end
  end
end
