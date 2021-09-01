class ReArtifactBaselinesController < RedmineReController
  before_action :load_re_artifact_baseline, only: [:update, :destroy, :revert, :preview]

  def new
    @re_artifact_baseline = ReArtifactBaseline.new

    respond_to do |format|
      format.js
    end
  end

  def create
    re_artifact_baseline = ReArtifactBaseline.new(resource_params)
    re_artifact_baseline.project = @project
    re_artifact_baseline.save
    re_artifact_baseline.bind_current_versions
  end

  def update
    @re_artifact_baseline.update(resource_params)
  end

  def destroy
    @re_artifact_baseline.destroy
  end

  def preview
    respond_to do |format|
      format.js
    end
  end

  def revert
    @re_artifact_baseline.revert!

    flash[:notice] = l('re_artifact_baseline_reverted', baseline: @re_artifact_baseline)

    redirect_to controller: 'requirements', action: 'index'
  end

  private

  def resource_params
    params.require(:re_artifact_baseline).permit(:name, :description)
  end

  def load_re_artifact_baseline
    @re_artifact_baseline = ReArtifactBaseline.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end