# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RubyLLM::Utils do
  describe '.deep_merge' do
    context 'with hash merging (existing functionality)' do
      it 'merges simple hashes' do
        original = { a: 1, b: 2 }
        overrides = { b: 3, c: 4 }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ a: 1, b: 3, c: 4 })
      end

      it 'deep merges nested hashes' do
        original = { 
          a: 1, 
          nested: { x: 1, y: 2 } 
        }
        overrides = { 
          a: 2, 
          nested: { y: 3, z: 4 } 
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          a: 2, 
          nested: { x: 1, y: 3, z: 4 } 
        })
      end

      it 'handles deeply nested hashes' do
        original = { 
          level1: { 
            level2: { 
              level3: { a: 1, b: 2 } 
            } 
          } 
        }
        overrides = { 
          level1: { 
            level2: { 
              level3: { b: 3, c: 4 } 
            } 
          } 
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          level1: { 
            level2: { 
              level3: { a: 1, b: 3, c: 4 } 
            } 
          } 
        })
      end
    end

    context 'with array merging (new functionality)' do
      it 'merges simple arrays by concatenation' do
        original = { items: [1, 2, 3] }
        overrides = { items: [4, 5] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: [1, 2, 3, 4, 5] })
      end

      it 'deep merges arrays containing hashes at corresponding indices' do
        original = { 
          content: [
            { type: 'text', text: 'hello' },
            { type: 'image', url: 'old.jpg' }
          ]
        }
        overrides = { 
          content: [
            { cache_control: { type: 'ephemeral' } },
            { url: 'new.jpg' }
          ]
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          content: [
            { type: 'text', text: 'hello', cache_control: { type: 'ephemeral' } },
            { type: 'image', url: 'new.jpg' }
          ]
        })
      end

      it 'appends additional array elements when override array is longer' do
        original = { 
          content: [
            { type: 'text', text: 'hello' }
          ]
        }
        overrides = { 
          content: [
            { cache_control: { type: 'ephemeral' } },
            { type: 'image', url: 'new.jpg' },
            { type: 'text', text: 'world' }
          ]
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          content: [
            { type: 'text', text: 'hello', cache_control: { type: 'ephemeral' } },
            { type: 'image', url: 'new.jpg' },
            { type: 'text', text: 'world' }
          ]
        })
      end

      it 'handles arrays with mixed types' do
        original = { items: ['string', { key: 'value' }, 42] }
        overrides = { items: [{ new_key: 'new_value' }, 'new_string'] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          items: [
            'string', 
            { key: 'value', new_key: 'new_value' }, 
            42, 
            'new_string'
          ]
        })
      end

      it 'handles nested arrays within hashes' do
        original = { 
          data: { 
            items: [
              { id: 1, name: 'first' },
              { id: 2, name: 'second' }
            ]
          }
        }
        overrides = { 
          data: { 
            items: [
              { active: true },
              { active: false },
              { id: 3, name: 'third', active: true }
            ]
          }
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          data: { 
            items: [
              { id: 1, name: 'first', active: true },
              { id: 2, name: 'second', active: false },
              { id: 3, name: 'third', active: true }
            ]
          }
        })
      end
    end

    context 'with mixed hash and array merging' do
      it 'handles complex nested structures with both hashes and arrays' do
        original = { 
          messages: [
            { 
              role: 'user', 
              content: [
                { type: 'text', text: 'Hello' }
              ]
            }
          ],
          config: { 
            temperature: 0.7,
            options: { stream: false }
          }
        }
        overrides = { 
          messages: [
            { 
              content: [
                { cache_control: { type: 'ephemeral' } },
                { type: 'image', url: 'test.jpg' }
              ]
            }
          ],
          config: { 
            temperature: 0.9,
            options: { max_tokens: 100 }
          }
        }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ 
          messages: [
            { 
              role: 'user', 
              content: [
                { type: 'text', text: 'Hello', cache_control: { type: 'ephemeral' } },
                { type: 'image', url: 'test.jpg' }
              ]
            }
          ],
          config: { 
            temperature: 0.9,
            options: { stream: false, max_tokens: 100 }
          }
        })
      end
    end

    context 'with type mismatches' do
      it 'replaces array with non-array value' do
        original = { items: [1, 2, 3] }
        overrides = { items: 'string' }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: 'string' })
      end

      it 'replaces non-array with array value' do
        original = { items: 'string' }
        overrides = { items: [1, 2, 3] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: [1, 2, 3] })
      end

      it 'replaces hash with non-hash value' do
        original = { config: { a: 1, b: 2 } }
        overrides = { config: 'string' }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ config: 'string' })
      end
    end

    context 'edge cases' do
      it 'handles empty arrays' do
        original = { items: [] }
        overrides = { items: [1, 2] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: [1, 2] })
      end

      it 'handles empty override arrays' do
        original = { items: [1, 2] }
        overrides = { items: [] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: [1, 2] })
      end

      it 'handles nil values' do
        original = { items: [1, nil, 3] }
        overrides = { items: [nil, 2] }
        
        result = described_class.deep_merge(original, overrides)
        
        expect(result).to eq({ items: [1, 2, 3] })
      end

      it 'does not mutate original hash' do
        original = { 
          items: [{ a: 1 }],
          config: { b: 2 }
        }
        overrides = { 
          items: [{ c: 3 }],
          config: { d: 4 }
        }
        
        original_copy = Marshal.load(Marshal.dump(original))
        described_class.deep_merge(original, overrides)
        
        expect(original).to eq(original_copy)
      end
    end
  end
end



