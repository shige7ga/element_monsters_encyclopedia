require "rails_helper"

RSpec.describe "Element seed" do
  def load_element_seeds
    Object.send(:remove_const, :ELEMENTS) if Object.const_defined?(:ELEMENTS)
    load Rails.root.join("db/seeds/elements.rb")
  end

  it "空のDBに118元素を作成する" do
    expect { load_element_seeds }.to change(Element, :count).by(118)

    hydrogen = Element.find_by!(atomic_number: 1)
    expect(hydrogen.attributes.slice("symbol", "name", "english_name", "common_state", "period", "group_number")).to eq(
      "symbol" => "H",
      "name" => "水素",
      "english_name" => "Hydrogen",
      "common_state" => "気体",
      "period" => 1,
      "group_number" => 1
    )
    expect(hydrogen.description).to eq("宇宙で最も多く存在する元素です。太陽などの恒星では、水素が核融合することで大きなエネルギーが生み出されています。")
  end

  it "既存Elementを更新せず、再実行しても重複を作成しない" do
    existing_attributes = {
      "symbol" => "CustomH",
      "name" => "変更後水素",
      "english_name" => "Customized Hydrogen",
      "common_state" => "液体",
      "description" => "管理画面から変更した水素の説明",
      "period" => 7,
      "group_number" => 18
    }
    hydrogen = create(:element, atomic_number: 1, **existing_attributes.transform_keys(&:to_sym))

    expect { load_element_seeds }.to change(Element, :count).by(117)
    expect(hydrogen.reload.attributes.slice(*existing_attributes.keys)).to eq(existing_attributes)

    expect { load_element_seeds }.not_to change(Element, :count)
    expect(hydrogen.reload.attributes.slice(*existing_attributes.keys)).to eq(existing_attributes)
  end
end
