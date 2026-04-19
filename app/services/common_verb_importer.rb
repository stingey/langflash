class CommonVerbImporter
  def initialize(user)
    @user = user
  end

  def call
    CardSeedImporter.import(@user, "common_verbs.csv")
  end
end
