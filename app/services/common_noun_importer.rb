class CommonNounImporter
  def initialize(user)
    @user = user
  end

  def call
    CardSeedImporter.import(@user, "common_nouns.csv")
  end
end
