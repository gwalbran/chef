require_relative 'spec_helper'

describe PostgresqlHelper do

  describe 'role diffs' do
    existing_roles = [
      { 'name' => 'role_name', 'privileges' => 'privs' },
      { 'name' => 'role_name2', 'privileges' => 'privs2' }
    ]

    before do
      allow(PostgresqlHelper).to receive(:load_roles_state).and_return(existing_roles)
    end

    it 'same roles returns empty array' do
      roles_from_recipe = existing_roles.dup

      expect(PostgresqlHelper.modified_roles("cluster", roles_from_recipe)).to eq([])
      expect(PostgresqlHelper.deleted_roles("cluster", roles_from_recipe)).to eq([])
    end

    it 'different returns modified role' do
      roles_from_recipe = existing_roles.dup
      new_role = { 'name' => 'new_role', 'privileges' => 'privs' }
      roles_from_recipe.push(new_role)

      expect(PostgresqlHelper.modified_roles("cluster", roles_from_recipe)).to eq([new_role])
      expect(PostgresqlHelper.deleted_roles("cluster", roles_from_recipe)).to eq([])
    end

    it 'different returns deleted role' do
      roles_from_recipe = existing_roles.dup
      old_role = { 'name' => 'old_role', 'privileges' => 'privs' }
      existing_roles.push(old_role)

      expect(PostgresqlHelper.modified_roles("cluster", roles_from_recipe)).to eq([])
      expect(PostgresqlHelper.deleted_roles("cluster", roles_from_recipe)).to eq([old_role])
    end

    it 'role rename' do
      roles_from_recipe = existing_roles.dup

      old_role = { 'name' => 'role_name3', 'privileges' => 'privs' }
      existing_roles.push(old_role)

      new_role = { 'name' => 'role_name4', 'privileges' => 'privs' }
      roles_from_recipe.push(new_role)

      expect(PostgresqlHelper.modified_roles("cluster", roles_from_recipe)).to eq([new_role])
      expect(PostgresqlHelper.deleted_roles("cluster", roles_from_recipe)).to eq([old_role])
    end
  end

end
