module dido.gui.scrollbar;

import std.algorithm;

import gfm.math;
import dido.gui;

class ScrollBar : UIElement
{
public:    

    this(UIContext context, int widthOfFocusBar, int padding, bool vertical)
    {
        super(context);
        _vertical = vertical;
        _widthOfFocusBar = widthOfFocusBar;
        _padding = padding;
        setProgress(0.45f, 0.55f);

        _state = State.initial;
    }

    // Called whenever a scrollbar move is done. Override it to change behaviour.
    void onScrollChangeMouse(float newProgressStart)
    {
        // do nothing
    }

    // Called whenever a scrollbar button is clicked. Override it to change behaviour.
    void onScrollChangeButton(bool up)
    {
        // do nothing
    }

    int thickness() pure const nothrow
    {
        return _widthOfFocusBar + 2 * _padding;
    }

    override void reflow(box2i availableSpace)
    {
        _position = availableSpace;
        _buttonSize = thickness();

        if (_vertical)
        {
            _position.min.x = _position.max.x - thickness();
        }
        else
        {
            _position.min.y = _position.max.y - thickness();
        }
    }

    override void preRender(SDL2Renderer renderer)
    {
        // Do not display useless scrollbar
        if (_progressStart <= 0.0f && _progressStop >= 1.0f)
            return;

        if (isMouseOver())
            renderer.setColor(42, 42, 46, 255);
        else
            renderer.setColor(32, 32, 36, 255);

        renderer.fillRect(0, 0, _position.width, _position.height);
        
        if (isMouseOver())
            renderer.setColor(140, 140, 140, 255);
        else
            renderer.setColor(100, 100, 100, 255);

        box2i focus = getFocusBox();
        roundedRect(renderer, focus);

        if (_vertical)
        {
            renderer.copy(context.image(UIImage.scrollbarN), 0, 0);
            renderer.copy(context.image(UIImage.scrollbarS), 0, _position.height - _buttonSize);
        }
        else
        {
            renderer.copy(context.image(UIImage.scrollbarW), 0, 0);
            renderer.copy(context.image(UIImage.scrollbarE), _position.width - _buttonSize, 0);
        }
    }

    void roundedRect(SDL2Renderer renderer, box2i b)
    {
        if (b.height > 2 && b.width > 2)
        {
            renderer.fillRect(b.min.x + 1, b.min.y    , b.width - 2, 1);
            renderer.fillRect(b.min.x    , b.min.y + 1, b.width    , b.height - 2);
            renderer.fillRect(b.min.x + 1, b.max.y - 1, b.width - 2, 1);
        }
        else
            renderer.fillRect(b.min.x, b.min.y, b.width, b.height);
    }

    void setProgress(float progressStart, float progressStop)
    {
        _progressStart = clamp!float(progressStart, 0.0f, 1.0f);
        _progressStop = clamp!float(progressStop, 0.0f, 1.0f);
        if (_progressStop < _progressStart)
            _progressStop = _progressStart;
    }

    int buttonSize() pure const nothrow
    {
        return _buttonSize;
    }

    override bool onMouseClick(int x, int y, int button, bool isDoubleClick)
    {
        // clicking on a button
        if (getButtonBoxA().contains(vec2i(x, y)))
        {
            onScrollChangeButton(true);
            return true;
        }
        else if (getButtonBoxB().contains(vec2i(x, y)))
        {
            onScrollChangeButton(false);
            return true;
        }        
        else
        {
            float clickProgress;
            if (_vertical)
            {
                int heightWithoutButton = _position.height - 2 * _buttonSize;
                clickProgress = cast(float)(y - _buttonSize) / heightWithoutButton;
            }
            else
            {
                int widthWithoutButton = _position.width - 2 * _buttonSize;
                clickProgress = cast(float)(x - _buttonSize) / widthWithoutButton;
            }                

            // now this clickProgress should move the _center_ of the scrollbar to it
            float newStartProgress = clickProgress - (_progressStop - _progressStart) * 0.5f;
            
            onScrollChangeMouse(newStartProgress);
        }
        return false;        
    }

private:

    int _widthOfFocusBar;
    int _padding;

    bool _vertical;
    float _progressStart;
    float _progressStop;
    int _buttonSize;

    State _state;

    enum State
    {
        initial,
        clicked, // dragging the scrollbar                
    }

    box2i getButtonBoxA()
    {
        return box2i(0, 0, 0 + _buttonSize, 0 + _buttonSize);
    }

    box2i getButtonBoxB()
    {
        int x = _vertical ? 0 : _position.width - _buttonSize;
        int y = _vertical ? _position.height - _buttonSize : 0;
        return box2i(x, y, x + _buttonSize, y + _buttonSize);
    }

    box2i getFocusBox()
    {
        if (_vertical)
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * (_position.height - 2 * _buttonSize - 2 * _padding));
            int iprogressStop = cast(int)(0.5f + _progressStop * (_position.height - 2 * _buttonSize - 2 * _padding));
            int x = _padding;
            int y = iprogressStart + _buttonSize + _padding;
            return box2i(x, y, x + _position.width - 2 * _padding, y + iprogressStop - iprogressStart);
        }
        else
        {
            int iprogressStart = cast(int)(0.5f + _progressStart * (_position.width - 2 * _buttonSize - 2 * _padding));
            int iprogressStop = cast(int)(0.5f + _progressStop * (_position.width - 2 * _buttonSize - 2 * _padding));
            int x = iprogressStart + _buttonSize + _padding;
            int y = _padding;
            return box2i(x, y, x + iprogressStop - iprogressStart, y + _position.height - 2 * _padding);
        }
    }
    
}