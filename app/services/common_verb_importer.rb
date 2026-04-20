class CommonVerbImporter
  CSV_FILE = "common_verbs.csv"

  def initialize(user)
    @user = user
  end

  def call(batch_size: CardSeedImporter::DEFAULT_BATCH_SIZE)
    CardSeedImporter.import(@user, CSV_FILE, batch_size: batch_size)
  end

  def progress
    CardSeedImporter.progress(@user, CSV_FILE)
  end
end
