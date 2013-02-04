metadata :name => 'package',
         :description => 'Checks the status of an installed package',
         :author => 'Pieter Loubser <pieter.loubser@puppetlabs.com>',
         :license => 'ASL2.0',
         :version => '1.0.0',
         :url => 'http://marionette-collective.org/',
         :timeout => 1

dataquery :description => 'Package' do
  input :query,
        :prompt => 'Package Name',
        :description => 'Package Name',
        :type => :string,
        :validation => :shellsafe,
        :maxlength => 50

  output :epoch,
         :description => "Package epoch number",
         :display_as  => "Epoch"

  output :arch,
         :description => "Package architecture",
         :display_as  => "Arch"

  output :ensure,
         :description => "Full package version",
         :display_as  => "Ensure"

  output :version,
         :description => "Version number",
         :display_as  => "Version"

  output :provider,
         :description => "Provider used to retrieve information",
         :display_as => "Provider"

  output :name,
         :description => "Package name",
         :display_as => "Name"

  output :release,
         :description => "Package release number",
         :display_as => "Release"
end
