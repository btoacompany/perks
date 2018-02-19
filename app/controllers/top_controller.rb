class TopController < ApplicationController
  def not_found
  	raise ActionController::RoutingError , "No routes matches #{request.path.inspect}"
  end

  def bad_request
  	raise ActionController::ParameterMissing, ""
  end

  def internal_server_error
  	raise Exception
  end

  def health_check
    head :ok
  end
end
