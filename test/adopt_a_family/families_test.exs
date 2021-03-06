defmodule AdoptAFamily.FamiliesTest do
  use AdoptAFamily.DataCase

  alias AdoptAFamily.Families
  alias AdoptAFamily.Families.{Child, Family, FamilyGift, Gift}

  describe "data creation" do
    setup do
      family_attrs = %{
        head_of_house: "Head of house",
        clinician: "Clinician"
      }

      child_attrs = %{
        name: "Child",
        gender: "female",
        age: 10,
        interests: "Soccer"
      }

      gift_attrs = %{
        item: "Soccer Ball"
      }

      size_gift_attrs = %{
        item: "Soccer Cleats",
        size: "Childs 9"
      }
      {:ok, family} = Families.create_family(family_attrs)
      {:ok, child} = Families.add_child(family, child_attrs)

      %{
        family_attrs: family_attrs,
        child_attrs: child_attrs,
        gift_attrs: gift_attrs,
        size_gift_attrs: size_gift_attrs,
        family: family,
        child: child
      }
    end

    test "create_family/1 with valid data creates a family", %{family_attrs: attrs} do
      assert {:ok, %Family{} = family} = Families.create_family(attrs)
      assert family.head_of_house == attrs.head_of_house
      assert family.clinician == attrs.clinician
    end

    test "add_child/2 with adds a child to the provided family", %{
      family: family, child_attrs: attrs
    } do
      assert {:ok, %Child{} = child} = Families.add_child(family, attrs)
      assert child.name == attrs.name
      assert child.gender == attrs.gender
      assert child.age == attrs.age
      assert child.interests == attrs.interests
    end

    test "add_gift/2 with a family creates a family gift", %{
      family: family, gift_attrs: attrs
    } do
      assert {:ok, %FamilyGift{} = gift} = Families.add_gift(family, attrs)
      assert gift.item == attrs.item
    end

    test "add_gift/2 with a child creates a gift", %{
      child: child, gift_attrs: attrs
    } do
      assert {:ok, %Gift{} = gift} = Families.add_gift(child, attrs)
      assert gift.item == attrs.item
    end

    test "add_gift/2 doesn't remove the first gift", %{
      family: %{id: family_id}, child: child, gift_attrs: gift_attrs, size_gift_attrs: attrs
    } do
      {:ok, %Gift{} = _gift} = Families.add_gift(child, gift_attrs)
      assert {:ok, %Gift{} = gift} = Families.add_gift(child, attrs)
      assert gift.item == attrs.item
      assert gift.size == attrs.size
      child_gifts = Families.children_from_family(family_id)
                    |> Enum.at(0)
                    |> Map.fetch!(:gifts)
      assert Enum.count(child_gifts) == 2
    end
  end

  describe "all" do
    setup do
      {:ok, family1} = Families.create_family(%{
        head_of_house: "Head of house1",
        clinician: "Clinician"
      })
      {:ok, family2} = Families.create_family(%{
        head_of_house: "Head of house2",
        clinician: "Clinician"
      })

      %{families: [family1, family2]}
    end

    test "all/0 returns a list of families", %{families: families} do
      assert Enum.count(Families.all) == Enum.count(families)
    end

    test "all/0 sums up the number of children for each family" do
      [family1, _] = Families.all
      assert family1.child_count == 0
    end
  end

  describe "get_family" do
    setup do
      {:ok, family} = Families.create_family(%{
        head_of_house: "Head of house1",
        clinician: "Clinician"
      })
      {:ok, gift} = Families.add_gift(family, %{item: "Kroger gift card"})
      {:ok, family_no_gift} = Families.create_family(%{
        head_of_house: "Head of house1",
        clinician: "Clinician"
      })

      %{
        family: family,
        family_no_gift: family_no_gift,
        gift: gift
      }
    end

    test "get_family/1 returns the family with preloaded gifts", %{family: staged_family, gift: gift} do
      family = Families.get_family(staged_family.id)
      assert family.head_of_house == staged_family.head_of_house
      assert family.clinician == staged_family.clinician
      assert family.family_gifts == [gift]
    end

    test "get_family/1 returns the family without exploding when no gifts", %{family_no_gift: staged_family} do
      family = Families.get_family(staged_family.id)
      assert family.head_of_house == staged_family.head_of_house
      assert family.clinician == staged_family.clinician
      assert family.family_gifts == []
    end

    test "get_family/1 raises an error if the family doesn't exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Families.get_family(0)
      end
    end
  end

  describe "children_from_family" do
    setup do
      {:ok, family} = Families.create_family(%{
        head_of_house: "Head of house",
        clinician: "Clinician"
      })

      {:ok, child1} = Families.add_child(family, %{
        name: "Child1",
        gender: "female",
        age: 10,
      })
      {:ok, child2} = Families.add_child(family, %{
        name: "Child2",
        gender: "male",
        age: 12,
      })

      {:ok, gift1} = Families.add_gift(child1, %{item: "Gift 1"})
      {:ok, gift2} = Families.add_gift(child1, %{item: "Gift 2"})
      {:ok, gift3} = Families.add_gift(child2, %{item: "Gift 3"})

      %{
        family_id: family.id,
        children: [child1, child2],
        child1_gifts: [gift1, gift2],
        child2_gifts: [gift3]
      }
    end

    test "children_from_family/1 returns an empty list if the family doesn't exist" do
      assert [] = Families.children_from_family(0)
    end

    test "children_from_family/1 gets all children and their gifts for the family", %{
      family_id: family_id, children: staged_children
    } = context do
      children = Families.children_from_family(family_id)
      assert Enum.count(children) == Enum.count(staged_children)
      Enum.each(children, fn child ->
        check_gifts(child, context)
      end)
    end

    def check_gifts(%Child{name: "Child1", gifts: gifts}, %{child1_gifts: expected_gifts}) do
      assert gifts == expected_gifts
    end
    def check_gifts(%Child{name: "Child2", gifts: gifts}, %{child2_gifts: expected_gifts}) do
      assert gifts == expected_gifts
    end
  end
end
